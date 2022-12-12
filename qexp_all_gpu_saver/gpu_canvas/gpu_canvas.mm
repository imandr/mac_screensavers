//
//  Field.cpp
//  qexp_all_gpu
//
//  Created by Igor on 12/9/22.
//

#include "gpu_canvas.hpp"
#import <ScreenSaver/ScreenSaver.h>
#include <stdio.h>
#import <Cocoa/Cocoa.h>
#include "util.h"
#include <errno.h>
#include <unistd.h>

@implementation GPUCanvas
{
    NSRect Bounds;
    NSRect Frame;

    id<MTLDevice> Device;

    // The compute pipeline generated from the compute kernel in the .metal shader file.
    id<MTLComputePipelineState> ClearPSO;
    id<MTLComputePipelineState> PixmapPSO;
    id<MTLComputePipelineState> PointsPSO;

    // The command queue used to pass commands to the device.
    id<MTLCommandQueue> CommandQueue;

    // Buffers to hold data.
    id<MTLBuffer> Buffer_R;
    id<MTLBuffer> Buffer_G;
    id<MTLBuffer> Buffer_B;
    id<MTLBuffer> Buffer_Pixmap;
    
    float* Pixels_R;
    float* Pixels_G;
    float* Pixels_B;
    unsigned int *Pixmap;
    int NPixels;

    FILE *log_file;
}

- (NSRect) bounds
{
    return Bounds;
}

- (instancetype) initWithDevice: (id<MTLDevice>) device frame:(NSRect)frame bounds:(NSRect) bounds
{
    self = [super init];
    if (self)
    {
        Device = device;
        NPixels = (int)(frame.size.width * frame.size.height);

        //
        // Fit the bounds into frame so that the horizontal and vertical scale are the same
        //
        float scale_x = (float)frame.size.width/(float)bounds.size.width;
        float scale_y = (float)frame.size.height/(float)bounds.size.height;
        
        NSRect fit_bounds = bounds;
        float scale;
        float center_x = bounds.origin.x + bounds.size.width/2.0;
        float center_y = bounds.origin.y + bounds.size.height/2.0;

        if( scale_x == scale_y )
        {
            ;   // do nothing
        }
        else if ( scale_x > scale_y )
        {
            scale = scale_y;
            float width = frame.size.width / scale;
            fit_bounds.origin.x = center_x - width/2;
            fit_bounds.size.width = width;
        }
        else
        {
            scale = scale_x;
            float height = frame.size.width / scale;
            fit_bounds.origin.y = center_y - height/2;
            fit_bounds.size.height = height;
        }
        
        Frame = frame;
        Bounds = fit_bounds;

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
                metal_library = [Device newDefaultLibraryWithBundle:b error:&error];
            }
        }

        if (metal_library == nil)
        {
            NSLog(@"Failed to find the default library.");
            return nil;
        }

        id<MTLFunction> clearFunction = [metal_library newFunctionWithName:@"clear"];
        if (clearFunction == nil)
        {
            NSLog(@"Failed to find the clear() function.");
            return nil;
        }
        id<MTLFunction> pixmapFunction = [metal_library newFunctionWithName:@"pixmap"];
        if (pixmapFunction == nil)
        {
            NSLog(@"Failed to find the pixmap() function.");
            return nil;
        }
        id<MTLFunction> pointsFunction = [metal_library newFunctionWithName:@"points"];
        if (pointsFunction == nil)
        {
            NSLog(@"Failed to find the points() function.");
            return nil;
        }

        // Create a compute pipeline state objects.
        ClearPSO = [Device newComputePipelineStateWithFunction: clearFunction error:&error];
        if (ClearPSO == nil)
        {
            //  If the Metal API validation is enabled, you can find out more information about what
            //  went wrong.  (Metal API validation is enabled by default when a debug build is run
            //  from Xcode)
            NSLog(@"Failed to created pipeline state object for clear() function, error %@.", error);
            return nil;
        }
        PixmapPSO = [Device newComputePipelineStateWithFunction: pixmapFunction error:&error];
        if (PixmapPSO == nil)
        {
            NSLog(@"Failed to created pipeline state object for pixmap() function, error %@.", error);
            return nil;
        }
        PointsPSO = [Device newComputePipelineStateWithFunction: pointsFunction error:&error];
        if (PixmapPSO == nil)
        {
            NSLog(@"Failed to created pipeline state object for points() function, error %@.", error);
            return nil;
        }

        CommandQueue = [Device newCommandQueue];
        if (CommandQueue == nil)
        {
            NSLog(@"Failed to find the command queue.");
            return nil;
        }
        
        int size = NPixels * sizeof(float);
        
        Buffer_R = [Device newBufferWithLength:size options:MTLResourceStorageModeShared];
        Buffer_G = [Device newBufferWithLength:size options:MTLResourceStorageModeShared];
        Buffer_B = [Device newBufferWithLength:size options:MTLResourceStorageModeShared];

        Pixels_R = (float*)Buffer_R.contents;
        Pixels_G = (float*)Buffer_G.contents;
        Pixels_B = (float*)Buffer_B.contents;
        
        Buffer_Pixmap = [Device
                         newBufferWithLength: NPixels * sizeof(unsigned int)
                         options:MTLResourceStorageModeShared
        ];
    }
    return self;
}

- (void) clear:(float *)color alpha:(float)alpha
{
    // Create a command buffer to hold commands.
    id<MTLCommandBuffer> commandBuffer = [CommandQueue commandBuffer];
    assert(commandBuffer != nil);

    // Start a compute pass.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    //fprintf(log_file, "executing with params: %f %f %f %f, direction: %d\n",
    //        params[0], params[1], params[2], params[3], _direction);
    //fflush(log_file);
    
    // Encode the pipeline state object and its parameters.
    [computeEncoder setComputePipelineState:ClearPSO];
    [computeEncoder setBytes:color length:3*sizeof(float) atIndex:0];
    [computeEncoder setBytes:&alpha length:sizeof(float) atIndex:1];
    [computeEncoder setBuffer:Buffer_R offset:0 atIndex:2];
    [computeEncoder setBuffer:Buffer_G offset:0 atIndex:3];
    [computeEncoder setBuffer:Buffer_B offset:0 atIndex:4];

    MTLSize gridSize = MTLSizeMake(NPixels, 1, 1);

    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = ClearPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > NPixels)
    {
        threadGroupSize = NPixels;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];

    // End the compute pass.
    [computeEncoder endEncoding];

    // Execute the command.
    [commandBuffer commit];

    // Normally, you want to do other work in your app while the GPU is running,
    // but in this example, the code simply blocks until the calculation is complete.
    //fprintf(log_file, "waiting... %f", t0);
    //fflush(log_file);
    
    [commandBuffer waitUntilCompleted];

    //fprintf(log_file, "done. time: %f delta: %f\n", t1, t1-t0);
    //fflush(log_file);
}

- (void) points:(int)n color:(float *)color alpha:(float)alpha x:(float *)x y:(float *)y
{
    // Create a command buffer to hold commands.
    id<MTLCommandBuffer> commandBuffer = [CommandQueue commandBuffer];
    assert(commandBuffer != nil);

    // Start a compute pass.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    //fprintf(log_file, "executing with params: %f %f %f %f, direction: %d\n",
    //        params[0], params[1], params[2], params[3], _direction);
    //fflush(log_file);
    
    // Encode the pipeline state object and its parameters.
    
    float origin[2];
    origin[0] = Bounds.origin.x;
    origin[1] = Bounds.origin.y;
    
    float range[2];
    range[0] = Bounds.size.width;
    range[1] = Bounds.size.height;
    
    int bounds[2];
    bounds[0] = Frame.size.width;
    bounds[1] = Frame.size.height;
    
    [computeEncoder setComputePipelineState:PointsPSO];
    [computeEncoder setBytes:color length:3*sizeof(float) atIndex:0];
    [computeEncoder setBytes:&alpha length:sizeof(float) atIndex:1];
    [computeEncoder setBytes:origin length:2*sizeof(float) atIndex:2];
    [computeEncoder setBytes:range length:2*sizeof(float) atIndex:3];
    [computeEncoder setBytes:bounds length:2*sizeof(int) atIndex:4];
#if 0
    id<MTLBuffer> x_buffer = [Device
                                   newBufferWithBytesNoCopy:x
                                   length:n*sizeof(float)
                                   options:MTLResourceStorageModeShared
                                   deallocator:nil
    ];
    id<MTLBuffer> y_buffer = [Device
                                   newBufferWithBytesNoCopy:y
                                   length:n*sizeof(float)
                                   options:MTLResourceStorageModeShared
                                   deallocator:nil
    ];
#else
    id<MTLBuffer> x_buffer = [Device
                                   newBufferWithBytes:x
                                   length:n*sizeof(float)
                                   options:MTLResourceStorageModeShared
    ];
    id<MTLBuffer> y_buffer = [Device
                              newBufferWithBytes:y
                                   length:n*sizeof(float)
                                   options:MTLResourceStorageModeShared
    ];
#endif
    [computeEncoder setBuffer:x_buffer offset:0 atIndex:5];
    [computeEncoder setBuffer:y_buffer offset:0 atIndex:6];
    [computeEncoder setBuffer:Buffer_R offset:0 atIndex:7];
    [computeEncoder setBuffer:Buffer_G offset:0 atIndex:8];
    [computeEncoder setBuffer:Buffer_B offset:0 atIndex:9];

    MTLSize gridSize = MTLSizeMake(n, 1, 1);

    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = PointsPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > n)
    {
        threadGroupSize = n;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];

    // End the compute pass.
    [computeEncoder endEncoding];

    // Execute the command.
    [commandBuffer commit];

    // Normally, you want to do other work in your app while the GPU is running,
    // but in this example, the code simply blocks until the calculation is complete.
    //fprintf(log_file, "waiting... %f", t0);
    //fflush(log_file);
    
    [commandBuffer waitUntilCompleted];

    //fprintf(log_file, "done. time: %f delta: %f\n", t1, t1-t0);
    //fflush(log_file);
}

- (unsigned int *) pixmap
{
    // Create a command buffer to hold commands.
    id<MTLCommandBuffer> commandBuffer = [CommandQueue commandBuffer];
    assert(commandBuffer != nil);

    // Start a compute pass.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    assert(computeEncoder != nil);
    
    //fprintf(log_file, "executing with params: %f %f %f %f, direction: %d\n",
    //        params[0], params[1], params[2], params[3], _direction);
    //fflush(log_file);
    
    // Encode the pipeline state object and its parameters.
    [computeEncoder setComputePipelineState:PixmapPSO];
    [computeEncoder setBuffer:Buffer_R offset:0 atIndex:0];
    [computeEncoder setBuffer:Buffer_G offset:0 atIndex:1];
    [computeEncoder setBuffer:Buffer_B offset:0 atIndex:2];
    [computeEncoder setBuffer:Buffer_Pixmap offset:0 atIndex:3];

    MTLSize gridSize = MTLSizeMake(NPixels, 1, 1);

    // Calculate a threadgroup size.
    NSUInteger threadGroupSize = PixmapPSO.maxTotalThreadsPerThreadgroup;
    if (threadGroupSize > NPixels)
    {
        threadGroupSize = NPixels;
    }
    MTLSize threadgroupSize = MTLSizeMake(threadGroupSize, 1, 1);

    // Encode the compute command.
    [computeEncoder dispatchThreads:gridSize
              threadsPerThreadgroup:threadgroupSize];

    // End the compute pass.
    [computeEncoder endEncoding];

    // Execute the command.
    [commandBuffer commit];

    // Normally, you want to do other work in your app while the GPU is running,
    // but in this example, the code simply blocks until the calculation is complete.
    //fprintf(log_file, "waiting... %f", t0);
    //fflush(log_file);
    
    [commandBuffer waitUntilCompleted];
    return (unsigned int*)Buffer_Pixmap.contents;

    //fprintf(log_file, "done. time: %f delta: %f\n", t1, t1-t0);
    //fflush(log_file);
}

- (void) render:(float*)capture_time render_time:(float*)render_time
{
    double t0 = millis();
    unsigned int* pixmap = [self pixmap];
    
    CGContextRef view_context = [[NSGraphicsContext currentContext] CGContext];
    CGDataProviderRef prov = CGDataProviderCreateWithData (NULL, (const void*)pixmap, 4*NPixels, NULL);
    CGImageRef cgi = CGImageCreate (Frame.size.width, Frame.size.height,
                                    8, 32, 4*Frame.size.width,
                                    CGColorSpaceCreateDeviceRGB(),
                                    /* Host-ordered, since we're using the
                                       address of an int as the color data. */
                                    kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host,
                                    //kCGImageAlphaPremultipliedFirst,
                                    prov,
                                    NULL,  /* decode[] */
                                    NO, /* interpolate */
                                    kCGRenderingIntentDefault);
    CGDataProviderRelease (prov);

#if 0
    // Save image
    NSURL *file_path = [NSURL fileURLWithPath:@"/tmp/image.png"];
    CGImageDestinationRef image_dest = CGImageDestinationCreateWithURL((CFURLRef)file_path, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(image_dest, cgi, NULL);
    CGImageDestinationFinalize(image_dest);
#endif
    
    *capture_time = millis() - t0;

    t0 = millis();
    CGRect r;
    r.origin = Frame.origin;
    r.size = Frame.size;
    CGContextDrawImage(view_context, r, cgi);
    *render_time = millis() - t0;
    CGImageRelease(cgi);
}

@end
