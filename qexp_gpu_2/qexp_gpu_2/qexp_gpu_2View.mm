//
//  qexp_gpu_2View.m
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/5/22.
//

#import <Cocoa/Cocoa.h>
#import <stdlib.h>
#import <time.h>
#import "qexp_gpu_2View.h"

@implementation qexp_gpu_2View
{
    double tbegin;
}

static double millis()
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

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    if( ! isPreview )
        log_file = fopen("/tmp/log", "w");
    
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1.0/25.0];
    }
    srand((int)(time(NULL)));
    [self log: @"initWithFrame"];
    Q = nil;
    C = new Canvas(frame.size.width, frame.size.height, -2.5, 2.5);
    static float HSBMin[3] = {0.0, 0.6, 0.8};
    static float HSBMax[3] = {2.0, 0.8, 1.0};
    CMorpher = new Morpher(3, HSBMin, HSBMax);

    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    [self log: @"startAnimation"];
    if( Q == nil )
    {
        Q = [[QExp alloc] initForPoints:50000];
        [self log: [NSString stringWithFormat:@"init: X:%x, Y:%x", [Q x], [Q y]]];
        [Q begin_step];
    }
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [Q end_step];
    fprintf(log_file, "elapsed:%f\n", Q.Elapsed);
    fflush(log_file);
    [Q begin_step];

    CMorpher -> step(0.01);
    C -> clear(0.0,0.0,0.0, 0.1);
    float *hsb = CMorpher->step(0.01);
    float h = hsb[0];
    float s = hsb[1];
    float b = hsb[2];
    //fprintf(log_file, "colors: %f %f %f\n", h, s, b);
    h -= (int)h;
    //while( h >= 1.0 )
    //    h -= 360;
    NSColor *c = [NSColor colorWithDeviceHue:h saturation:s brightness:b alpha:0.2];
    //[self log:[NSString stringWithFormat:@"h:%f s:%f b:%f -> r:%f g:%f b:%f",
    //           h, s, b, [c redComponent], [c greenComponent], [c blueComponent]]];
    double t0 = millis();
    C -> points(Q.NPoints, [Q x], [Q y],
                [c redComponent], [c greenComponent], [c blueComponent], 0.2, 1.0);
    fprintf(log_file, "points time:%f n:%d\n", millis() - t0, Q.NPoints);
    //C -> points(F->N, F->x, F->y, [c redComponent], [c greenComponent], [c blueComponent], 0.2, 1.0);
    C -> render();
    fprintf(log_file, "rendering time:%f\n", millis() - t0);
    fflush(log_file);

}

- (void)animateOneFrame
{
    //[self log: @"animateOneFrame"];
    
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
