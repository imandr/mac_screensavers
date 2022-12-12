//
//  qexp_gpu.m
//  saver
//
//  Created by Igor Mandrichenko on 12/4/22.
//

#import "qexp_gpu.h"
#include <stdlib.h>
#include "morpher.hpp"

#define rnd(x) ((rand()%1000000)/1000000.0*x)

double millis()
{
    struct timespec spec;
    clock_gettime(CLOCK_REALTIME, &spec);
    time_t s  = spec.tv_sec;
    long ms = round(spec.tv_nsec / 1.0e6); // Convert nanoseconds to milliseconds
    if (ms > 999) {
        s++;
        ms = 0;
    }
    return (double)s + ((double)ms)/1000;
}

static inline float G(float x)
{
    return 3*(x*x*x - 1.2*x)*exp(-x*x);
}

static inline float F(float x)
{
    return (1-3.5*x*x)*exp(-x*x);
}

static inline float H(float x)
{
    return 2.3*x*exp(-x*x);
}

void step(float x, float y, float *params, float *xout, float *yout)
{
    float A = params[0];
    float B = params[1];
    float C = params[2];
    float D = params[3];
    
    *xout = G(x*A) + F(y*B);
    *yout = G(y*C) + F(x*D);
}

@implementation QExpGPU
{
    id<MTLDevice> _mDevice;
    
    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> _mAddFunctionPSO;
    
    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _mCommandQueue;
    
    // Buffers to hold data.
    id<MTLBuffer> _BufferXA;
    id<MTLBuffer> _BufferXB;
    id<MTLBuffer> _BufferYA;
    id<MTLBuffer> _BufferYB;
    id<MTLBuffer> _BufferParams;
    Morpher *PMorpher;
    id<MTLBuffer> _BufferSrcX;
    id<MTLBuffer> _BufferSrcY;
    id<MTLBuffer> _BufferDstX;
    id<MTLBuffer> _BufferDstY;
    id<MTLCommandBuffer> commandBuffer;
    FILE *log_file;
    double tstart;
}

- (instancetype) initForPoints: (int) n
{
    self = [super init];
    if (self)
    {
        log_file = fopen("/tmp/qexp.log", "w");
        fprintf(log_file, "--- initForPoints: %d ---\n", n);
        fflush(log_file);

        _mDevice = MTLCreateSystemDefaultDevice();
        //fprintf(log_file, "device: %x\n", _mDevice);
        //fflush(log_file);
        
        NSError* error = nil;
        
        // Load the shader files with a .metal file extension in the project
        NSArray <NSBundle*> *bundles = [NSBundle allBundles];
        long nbundles = [bundles count];
        int i;
        id<MTLLibrary> metal_library = nil;
        for( i = 0; i < nbundles; i++ )
        {
            NSBundle* b = [bundles objectAtIndex:i];
            if( [b.bundlePath containsString:@"qexp_gpu"] )
            {
                metal_library = [_mDevice newDefaultLibraryWithBundle:b error:&error];
                fprintf(log_file, "Library loaded from %s: %x\n", b.bundlePath.UTF8String, metal_library);
            }
        }

        if (metal_library == nil)
        {
            NSLog(@"Failed to find the default library.");
            fprintf(log_file, "Failed to find the default library\n");
            fflush(log_file);
            return nil;
        }
        
        id<MTLFunction> addFunction = [metal_library newFunctionWithName:@"qexp_step"];
        if (addFunction == nil)
        {
            fprintf(log_file, "Failed to find the adder function.\n");
            NSLog(@"Failed to find the adder function.");
            fflush(log_file);
            return nil;
        }
        
        // Create a compute pipeline state object.
        _mAddFunctionPSO = [_mDevice newComputePipelineStateWithFunction: addFunction error:&error];
        if (_mAddFunctionPSO == nil)
        {
            //  If the Metal API validation is enabled, you can find out more information about what
            //  went wrong.  (Metal API validation is enabled by default when a debug build is run
            //  from Xcode)
            fprintf(log_file, "Failed to created pipeline state object, error\n");
            fflush(log_file);
            NSLog(@"Failed to created pipeline state object, error %@.", error);
            return nil;
        }
        
        _mCommandQueue = [_mDevice newCommandQueue];
        if (_mCommandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            fprintf(log_file, "Failed to find the command queue.\n");
            fflush(log_file);
            return nil;
        }
        
        const unsigned int bufferSize = n * sizeof(float);
        static float pmin[4] = {0.1, 0.1, 0.1, 0.1};
        static float pmax[4] = {0.7, 0.7, 0.7, 0.7};
        PMorpher = new Morpher(4, pmin, pmax);
        _NPoints = n;
        // Allocate three buffers to hold our initial data and the result.
        _BufferXA = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
        _BufferXB = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
        _BufferYA = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
        _BufferYB = [_mDevice newBufferWithLength:bufferSize options:MTLResourceStorageModeShared];
        _BufferParams = [_mDevice newBufferWithLength: PMorpher->N * sizeof(float) options:MTLResourceStorageModeShared];
        
        //fprintf(log_file, "bufferSize: %d, XA.contents: %x\n", bufferSize, _BufferXA.contents);
        
        float *ya = (float*)_BufferYA.contents;
        float *yb = (float*)_BufferYB.contents;
        float *xa = (float*)_BufferXA.contents;
        float *xb = (float*)_BufferXB.contents;
        for( i = 0; i < n; i++ )
        {
            xa[i] = rnd(2.0)-1.0;
            xb[i] = rnd(2.0)-1.0;
            ya[i] = rnd(2.0)-1.0;
            yb[i] = rnd(2.0)-1.0;
        }

        _BufferSrcX = _BufferXA;
        _BufferSrcY = _BufferYA;
        _BufferDstX = _BufferXB;
        _BufferDstY = _BufferYB;
        
        commandBuffer = NULL;
        [self log: @"initialization complete"];
    }
    return self;
}

- (void) begin_step
{
    //[self log:@"begin_step..."];
    int arrayLength = _NPoints;
    tstart = millis();
    // Create a command buffer to hold commands.
    
    commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);
    
    // Start a compute pass.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
  
    float *params = PMorpher->step(0.01);
    float *params_buf = (float*)_BufferParams.contents;
    int i;
    for(i=0; i<4; i++)
    {
        params_buf[i] = params[i];
        //fprintf(log_file, "param[%d] = %f, ", i, params[i]);
    }
    
    //fprintf(log_file, "\n");
    //fflush(log_file);
    
    float *src_x = (float*)_BufferSrcX.contents;
    float *src_y = (float*)_BufferSrcY.contents;

    for(i=0; i<_NPoints; i++, src_x++, src_y++)
        if( rnd(1.0) < 0.01 )
        {
            *src_x = rnd(2.0)-1;
            *src_y = rnd(2.0)-1;
        }
    
    // Encode the pipeline state object and its parameters.
    [computeEncoder setComputePipelineState:_mAddFunctionPSO];
    [computeEncoder setBuffer:_BufferSrcX offset:0 atIndex:0];
    [computeEncoder setBuffer:_BufferSrcY offset:0 atIndex:1];
    [computeEncoder setBuffer:_BufferParams offset:0 atIndex:2];
    [computeEncoder setBuffer:_BufferDstX offset:0 atIndex:3];
    [computeEncoder setBuffer:_BufferDstY offset:0 atIndex:4];
    
    MTLSize gridSize = MTLSizeMake(arrayLength, 1, 1);
    
    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = _mAddFunctionPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > arrayLength)
    {
        threadGroupSize = arrayLength;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);
    
    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize threadsPerThreadgroup:threadgroupSize];
    
    // --------- end encode
    
    // End the compute pass.
    [computeEncoder endEncoding];
    
    // Execute the command.
    [commandBuffer commit];
    
}

- (void) end_step
{
    //[self log:@"end_step..."];
    [commandBuffer waitUntilCompleted];
    //[self log:@"computation complete"];
    //fflush(log_file);
#if 0
    int i;
    float x = *(float*)(_BufferSrcX.contents);
    float y = *(float*)(_BufferSrcY.contents);
    float x1 = *(float*)(_BufferDstX.contents);
    float y1 = *(float*)(_BufferDstY.contents);
    float params[4] = {1.0, 1.0, 1.0, 1.0};   //(float*)_BufferParams.contents;
    float x2, y2;
    step(x, y, params, &x2, &y2);
    fprintf(log_file, "x,y: %f, %f, params: %f, %f, %f, %f, expected: %f, %f, calculated: %f, %f\n",
            x, y, 1.0,1.0,1.0,1.0,
            x2, y2, x1, y1);
    fflush(log_file);
#endif
    
    id<MTLBuffer> tmp = _BufferSrcX;
    _BufferSrcX = _BufferDstX;
    _BufferDstX = tmp;
    
    tmp = _BufferSrcY;
    _BufferSrcY = _BufferDstY;
    _BufferDstY = tmp;
    _Elapsed = millis() - tstart;
}

- (float *)x
{
    return (float *)(_BufferSrcX.contents);
}

- (float *)y
{
    return (float *)(_BufferSrcY.contents);
}

- (void) log: (NSString *) message
{
    fprintf(log_file, "%s\n", message.UTF8String);
    fflush(log_file);
}
@end

