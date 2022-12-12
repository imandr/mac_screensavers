//
//  qexp_gpu_2View.m
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/5/22.
//

#import <Cocoa/Cocoa.h>
#import <stdlib.h>
#import <time.h>
#import "QExpView.h"
#include "util.h"

@implementation QExpView
{
    double tbegin;
    float dt;
    bool animating;
    int initial_skip;
    double last_draw;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];

    if( ! isPreview )
        log_file = fopen("/tmp/log", "w");
    
    if (self) {
        [self setAnimationTimeInterval:1.0/25.0];
    }
    srand((int)(time(NULL)));
    [self log: @"initWithFrame"];
    initial_skip = 20;
    animating = NO;
    last_draw = millis();
    
    NSRect bounds;
    bounds.origin.x = -3.5;
    bounds.origin.y = -3.5;
    bounds.size.width = 7.0;
    bounds.size.height = 7.0;
    
    [self log: @"creting Canvas..."];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    C = [[GPUCanvas alloc] initWithDevice: device frame:frame bounds:bounds];

    [self log: @"creting QExp..."];
    Q = [[QExp alloc] initWithDevice:device npoints:200000];

    static float HSBMin[3] = {0.0, 0.2, 0.8};
    static float HSBMax[3] = {3.0, 0.9, 1.0};
    CMorpher = new HSBMorpher();
    
    static float PMin[4] = {0.2, 0.2, 0.2, 0.2};
    static float PMax[4] = {1.7, 1.7, 1.7, 1.7};
    PMorpher = new Morpher(4, PMin, PMax);
    
    dt = 0.03;

    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    [self log: @"startAnimation"];
    for( ; initial_skip > 0; --initial_skip )
        [Q step:PMorpher->P];
    animating = YES;
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    //[self log: @"drawRect"];
    if( !animating )
        return;                 // not initialized yet
    float black[3] = {0,0,0};
    [C clear:black alpha:0.2];

    float rgb[3];
    CMorpher->step(0.1);
    CMorpher->rgb(rgb);
    double t0 = millis();
    //fprintf(log_file, "colors: HSB: %f %f %f    -> RGB: %f %f %f\n", h, s, b, rgb[0], rgb[1], rgb[2]);
    //fflush(log_file);
    //fprintf(log_file, "points %d ...\n", [Q N]);
    //fflush(log_file);
    //float *xx = [Q x];
    //float *yy = [Q y];
    //for( int i=0; i<10; i++)
    //    fprintf(log_file, "  i:%d x:%f y:%f\n", i, xx[i], yy[i]);
    //fflush(log_file);
    [Q end_step];
    double tw = millis();
    double wait_time = tw - t0;

    [C points:[Q N] color:rgb alpha:0.05 x:[Q x] y:[Q y]];
    double tp = millis();
    double points_time = tp - tw;
    
    float *params = PMorpher -> step(dt);
    [Q begin_step:params];
    double ts = millis();
    double start_step_time = ts - tw;

    
    double t1 = millis();
    //fprintf(log_file, "points (%d) time:%f\n", Q.N, t1 - t0);
    float capture_time, render_time;
    [C render:&capture_time render_time:&render_time];

    double t2 = millis();
#if 0
    fprintf(log_file, "wait time:%f points time: %f start_step_time:%f rendering time:%f (capture:%f, render:%f) frame time:%f\n",
            wait_time, points_time, start_step_time, t2-t1, capture_time, render_time, t2 - last_draw);
    fflush(log_file);
#endif
    last_draw = t2;
}

- (void)animateOneFrame
{
#if 0
    //[self log: @"animateOneFrame"];
    float *params = PMorpher -> step(dt);
    //[self log: @"executing..."];
    double t0 = millis();
    step_handle = [Q begin_step:params];
    double t1 = millis();
    fprintf(log_file, "step time:%f\n", t1-t0);
    fflush(log_file);
#endif
    [self setNeedsDisplay:YES];
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}


- (void) log:(NSString*) message
{
    if( log_file != nil )
    {
        fprintf(log_file, "log: %s\n", message.UTF8String);
        fflush(log_file);
    }
}


@end
