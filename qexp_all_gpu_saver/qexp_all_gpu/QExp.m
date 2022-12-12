/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to manage all of the Metal objects this app creates.
*/

#import "QExp.h"
#include <stdlib.h>
#include "qexp_c.h"

#include "util.hpp"

#define rnd(x) (x*((float)rand())/RAND_MAX)


@implementation QExp
{
    id<MTLDevice> _mDevice;

    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> _mAddFunctionPSO;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> _mCommandQueue;

    // Buffers to hold data.
    id<MTLBuffer> _mBufferX_A;
    id<MTLBuffer> _mBufferX_B;
    id<MTLBuffer> _mBufferY_A;
    id<MTLBuffer> _mBufferY_B;
    id<MTLBuffer> input_x;
    id<MTLBuffer> output_x;
    id<MTLBuffer> input_y;
    id<MTLBuffer> output_y;
    id<MTLCommandBuffer> step_command;
    int _bufferSize;
    int _paramsSize;
    int PreRun;
    FILE *log_file;
}

- (instancetype) initWithDevice: (id<MTLDevice>) device npoints:(int)npoints
{
    self = [super init];
    if (self)
    {
        _mDevice = device;
        _N = npoints;
        _bufferSize = npoints * sizeof(float);
        _paramsSize = 4 * sizeof(float);
        step_command = nil;
        PreRun = 10;
        log_file = fopen("/tmp/qexp.log", "w");
        fprintf(log_file, "initWithDevice: npoints: %d\n", _N);
        fflush(log_file);

        NSError* error = nil;

        // Load the shader files with a .metal file extension in the project
        NSArray <NSBundle*> *bundles = [NSBundle allBundles];
        long nbundles = [bundles count];
        int i;
        id<MTLLibrary> metal_library = nil;
        for( i = 0; i < nbundles; i++ )
        {
            NSBundle* b = [bundles objectAtIndex:i];
            if( [b.bundlePath containsString:@"qexp"] )
            {
                metal_library = [_mDevice newDefaultLibraryWithBundle:b error:&error];
                //fprintf(log_file, "Library loaded from %s: %x\n", b.bundlePath.UTF8String, metal_library);
                //fflush(log_file);
            }
        }

        if (metal_library == nil)
        {
            NSLog(@"Failed to find the default library.");
            fprintf(log_file, "Failed to find the default library\n");
            fflush(log_file);
            return nil;
        }

        id<MTLFunction> addFunction = [metal_library newFunctionWithName:@"qexp"];
        if (addFunction == nil)
        {
            NSLog(@"Failed to find the adder function.");
            return nil;
        }

        // Create a compute pipeline state object.
        _mAddFunctionPSO = [_mDevice newComputePipelineStateWithFunction: addFunction error:&error];
        if (_mAddFunctionPSO == nil)
        {
            //  If the Metal API validation is enabled, you can find out more information about what
            //  went wrong.  (Metal API validation is enabled by default when a debug build is run
            //  from Xcode)
            NSLog(@"Failed to created pipeline state object, error %@.", error);
            return nil;
        }

        _mCommandQueue = [_mDevice newCommandQueue];
        if (_mCommandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            return nil;
        }
    }

    //
    // init data
    //
    _mBufferX_A = [_mDevice newBufferWithLength:_bufferSize options:MTLResourceStorageModeShared];
    _mBufferY_A = [_mDevice newBufferWithLength:_bufferSize options:MTLResourceStorageModeShared];
    _mBufferX_B = [_mDevice newBufferWithLength:_bufferSize options:MTLResourceStorageModeShared];
    _mBufferY_B = [_mDevice newBufferWithLength:_bufferSize options:MTLResourceStorageModeShared];

    [self generateRandomFloatData:_mBufferX_A];
    [self generateRandomFloatData:_mBufferX_B];
    [self generateRandomFloatData:_mBufferY_A];
    [self generateRandomFloatData:_mBufferY_B];
    
    input_x = _mBufferX_A;
    input_y = _mBufferY_A;
    output_x = _mBufferX_B;
    output_y = _mBufferY_B;

    return self;
}

const float KickRatio = 0.02;

- (void) flip
{
    id<MTLBuffer> tmp;

    tmp = input_x;
    input_x = output_x;
    output_x = tmp;
    tmp = input_y;
    input_y = output_y;
    output_y = tmp;
}

- (void) step:(float*)params
{
    [self begin_step:params];
    [self end_step];
}

- (void) begin_step:(float*)params
{
    [self flip];

#if 0
    // kick
    int length = (int)(_N * KickRatio);
    int fragment = rand() % (_N - length + 1);
    float *in_x = (float*)input_x.contents + fragment;
    float *in_y = (float*)input_y.contents + fragment;
    float tmp_x[length];
    float tmp_y[length];
    
    qexp_c(length, in_x, in_y, params, tmp_x, tmp_y);
    qexp_c(length, tmp_x, tmp_y, params, in_x, in_y);
    qexp_c(length, in_x, in_y, params, tmp_x, tmp_y);
    qexp_c(length, tmp_x, tmp_y, params, in_x, in_y);
#endif
    
#if 0
    int length = (int)(_N * KickRatio);
    float tmp_x[length], tmp_y[length];
    float tmp_x2[length], tmp_y2[length];
    int i;
    for( i = 0; i < length; i++ )
    {
        tmp_x[i] = rnd(2.0)-1.0;
        tmp_y[i] = rnd(2.0)-1.0;
    }

    qexp_c(length, tmp_x, tmp_y, params, tmp_x2, tmp_y2);
    qexp_c(length, tmp_x2, tmp_y2, params, tmp_x, tmp_y);

    int j = 0;
    int i0 = rand() % _N;
    for( j=i=0; i<_N && j<length; i++ )
        if( rnd(1.0) < KickRatio )
        {
            int ii = (i+i0) % _N;
            ((float*)(input_x.contents))[ii] = tmp_x[j];
            ((float*)(input_y.contents))[ii] = tmp_y[j];
            ++j;
        }
#endif

#if 0
    fprintf(log_file, "kicked:\n");
    for(i=0; i<10; i++)
        fprintf(log_file, "   i:%d x:%f y:%f\n", i, tmp_x[i], tmp_y[i] );
    fflush(log_file);
#endif

#if 1
    int n = (int)(_N * KickRatio);
    for( ; n > 0 ; n-- )
    {
        int i = rand() % _N;
        ((float*)input_x.contents)[i] = rnd(2)-1;
        ((float*)input_y.contents)[i] = rnd(2)-1;
    }
#endif
    step_command = [self begin_step_gpu:params];
}

- (void) end_step
{
    if( step_command != nil )
        [self end_step_gpu:step_command];
    step_command = nil;
}

- (id<MTLCommandBuffer>) begin_step_gpu:(float*)params
{
    // Create a command buffer to hold commands.
    id<MTLCommandBuffer> commandBuffer = [_mCommandQueue commandBuffer];
    assert(commandBuffer != nil);

    // Start a compute pass.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    //fprintf(log_file, "executing with params: %f %f %f %f, direction: %d\n",
    //        params[0], params[1], params[2], params[3], _direction);
    //fflush(log_file);
    
    //fprintf(log_file, "out buffers: %x %x, contents: %x %x\n",
    //        output_x, output_y, output_x.contents, output_y.contents);
    
    [self encodeCommand:computeEncoder
            input_x:input_x input_y:input_y
                 params:params
            output_x:output_x output_y:output_y];

    // End the compute pass.
    [computeEncoder endEncoding];

    // Execute the command.
    [commandBuffer commit];

    // Normally, you want to do other work in your app while the GPU is running,
    // but in this example, the code simply blocks until the calculation is complete.
    //fprintf(log_file, "waiting... %f", t0);
    //fflush(log_file);
    
    return commandBuffer;
    
    //[commandBuffer waitUntilCompleted];

    //fprintf(log_file, "done. time: %f delta: %f\n", t1, t1-t0);
    //fflush(log_file);

}

- (void) end_step_gpu:(id<MTLCommandBuffer>)command_buffer
{
    [command_buffer waitUntilCompleted];
}

- (float*) x
{
    return output_x.contents;
}

- (float*) y
{
    return output_y.contents;
}

- (void)encodeCommand:(id<MTLComputeCommandEncoder>)computeEncoder
              input_x:(id<MTLBuffer>)input_x
              input_y:(id<MTLBuffer>)input_y
               params:(float*)params
             output_x:(id<MTLBuffer>)output_x
             output_y:(id<MTLBuffer>)output_y
{

    // Encode the pipeline state object and its parameters.
    [computeEncoder setComputePipelineState:_mAddFunctionPSO];
    
    [computeEncoder setBuffer:input_x offset:0 atIndex:0];
    [computeEncoder setBuffer:input_y offset:0 atIndex:1];
    [computeEncoder setBytes:params length:_paramsSize atIndex:2];
    [computeEncoder setBuffer:output_x offset:0 atIndex:3];
    [computeEncoder setBuffer:output_y offset:0 atIndex:4];

    MTLSize gridSize = MTLSizeMake(_N, 1, 1);

    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = _mAddFunctionPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > _N)
    {
        threadGroupSize = _N;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];
}

- (void) generateRandomFloatData: (id<MTLBuffer>) buffer
{
    float* dataPtr = buffer.contents;

    for (unsigned long index = 0; index < _N; index++)
    {
        dataPtr[index] = rnd(2.0)-1.0;
    }
}

- (void) verifyResultsInX:(float*) in_x
                      inY:(float*) in_y
                   params:(float*) params
                     outX:(float*) out_x
                     outY:(float*) out_y
{
    float *c_x, *c_y;
    c_x = (float*)calloc(_N, sizeof(float));
    c_y = (float*)calloc(_N, sizeof(float));
    
    qexp_c(_N, in_x, in_y, params, c_x, c_y);
    
#define cmp(x, y) ((int)((x)*1000) == (int)((y)*1000))

    for (long index = 0; index < _N; index++)
    {
        if (!cmp(c_x[index], out_x[index]))
        {
            printf("Compute ERROR: x: index=%lu result=%g vs %g\n",
                   index, out_x[index], c_x[index]);
            assert(cmp(c_x[index], out_x[index]));
        }
    }
    printf("Compute results as expected\n");
}
@end
