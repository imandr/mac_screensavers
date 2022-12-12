//
//  qexp_gpu_2View.m
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/5/22.
//

#import <Cocoa/Cocoa.h>
#import <stdlib.h>
#import <time.h>
#import "DoubleQExpView.h"
#include "util.h"

@implementation DoubleQExpView
{
    FILE* log_file;
    GPUCanvas *C;
    HSBMorpher *CMorpher1;      // Color morpher
    HSBMorpher *CMorpher2;      // Color morpher
    Morpher *PMorpher1;      // Params morpher
    Morpher *PMorpher2;      // Params morpher
    Morpher *SMorpher;      // Q1/Q2 share morpher
    QExp *Q1;
    QExp *Q2;

    double tbegin;
    float dt;
    bool animating;
    int initial_skip;
    float params2[4];
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];

    if( ! isPreview )
        log_file = fopen("/tmp/log", "w");
    
    if (self) {
        [self setAnimationTimeInterval:1.0/10.0];
    }
    srand((int)(time(NULL)));
    [self log: @"initWithFrame"];

    animating = NO;
    initial_skip = 100;
    
    NSRect bounds;
    bounds.origin.x = -3.5;
    bounds.origin.y = -3.5;
    bounds.size.width = 7.0;
    bounds.size.height = 7.0;
    
    [self log: @"creting Canvas..."];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    C = [[GPUCanvas alloc] initWithDevice: device frame:frame bounds:bounds];

    [self log: @"creting QExp1..."];
    Q1 = [[QExp alloc] initWithDevice:device npoints:50000];
    [self log: @"creting QExp2..."];
    Q2 = [[QExp alloc] initWithDevice:device npoints:50000];

    CMorpher1 = new HSBMorpher();
    CMorpher2 = new HSBMorpher();

    static float PMin[4] = {0.2, 0.2, 0.2, 0.2};
    static float PMax[4] = {1.7, 1.7, 1.7, 1.7};
    PMorpher1 = new Morpher(4, PMin, PMax);
    for( int i=0; i<4; i++)
        params2[i] = PMorpher1->P[i];
    PMorpher2 = new Morpher(4, PMin, PMax);

    static float SMin[1] = {0.01};
    static float SMax[1] = {0.99};
    SMorpher = new Morpher(1, SMin, SMax);
    
    dt = 0.03;

    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    [self log: @"startAnimation"];
    for( ; initial_skip > 0; --initial_skip )
    {
        [Q1 step:PMorpher1->P];
        [Q2 step:PMorpher2->P];
    }
    animating = YES;

    animating = YES;
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    const float PAlpha = 0.1;
    //[self log: @"drawRect"];
    if( !animating )
        return;
    float black[3] = {0,0,0};
    [C clear:black alpha:0.2];

    CMorpher1->step(0.1);
    CMorpher2->step(0.1);
    float rgb1[3];
    float rgb2[3];

    CMorpher1->rgb(rgb1);
    CMorpher2->rgb(rgb2);
    
    float share = SMorpher -> step(1.0)[0];
    //share = share * share;
    
    //fprintf(log_file, "share: %f\n", share);
    //fflush(log_file);

    double t0 = millis();

    float *params1 = PMorpher1 -> step(dt);
    float *params2 = PMorpher2 -> step(dt);
    
    const float beta = 0.05;
    const float gamma = 0.05;
    
    float p1[PMorpher1->N];     // assume morphers have the same dimensions
    float p2[PMorpher1->N];

    
    for( int i = 0; i < PMorpher1->N; i++ )
    {
        p1[i] = params1[i];
        p2[i] = (1-beta) * params1[i] + beta * params2[i];
    }

    [Q1 end_step];
    [C points:[Q1 N] color:rgb1 alpha:PAlpha*share x:[Q1 x] y:[Q1 y]];
    [Q1 begin_step:p1];

    [Q2 end_step];
    [C points:[Q2 N] color:rgb2 alpha:PAlpha*(1.0-share) x:[Q2 x] y:[Q2 y]];
    [Q2 begin_step:p2];

    double t1 = millis();
    fprintf(log_file, "points (%d) time:%f\n", Q1.N, t1 - t0);
    float capture_time, render_time;
    [C render:&capture_time render_time:&render_time];

    double t2 = millis();
    fprintf(log_file, "rendering time:%f (capture:%f, render:%f)\n", t2-t1, capture_time, render_time);
    fflush(log_file);
}

- (void)animateOneFrame
{
    //[self log: @"animateOneFrame"];
#if 0
    float *params1 = PMorpher1 -> step(dt);
    float *params2 = PMorpher2 -> step(dt);
    //[self log: @"executing..."];
    //double t0 = millis();
        
    float p1[PMorpher1->N];     // assume morphers have the same dimensions
    float p2[PMorpher1->N];

    const float beta = 0.45;
    
    for( int i = 0; i < PMorpher1->N; i++ )
    {
        p1[i] = (1-beta) * params1[i] + beta * params2[i];
        p2[i] = (1-beta) * params2[i] + beta * params1[i];
    }
    
    [Q1 step:p1];
    [Q2 step:p2];
#endif
    //double t1 = millis();
    //fprintf(log_file, "execution complete. time:%f\n", t1-t0);
    //fflush(log_file);

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
