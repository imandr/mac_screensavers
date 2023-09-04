//
//  saverView.m
//  saver
//
//  Created by Igor Mandrichenko on 11/29/22.
//

#import "saverView.h"
#include <stdio.h>
#include "canvas.hpp"
#import <Cocoa/Cocoa.h>
#import "qexp_gpu.h"

@implementation saverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
    }
    if( ! isPreview )
        log_file = fopen("/tmp/log", "w");

    [self log: @"initWithFrame"];
    if( isPreview )
        [self log: @"    preview"];

    srand(time(NULL));
    //Q = NULL;       // to be initialized later
    return self;
}

- (void)startAnimation
{
    [self log: @"startAnimation"];
    [super startAnimation];
    if( Q == NULL )
    {
        static float HSBMin[3] = {0.0, 0.6, 0.8};
        static float HSBMax[3] = {1080.0, 0.8, 1.0};
        CMorpher = new Morpher(3, HSBMin, HSBMax);
        Q = [[QExp alloc] initForPoints:1000];
        [self log: [NSString stringWithFormat:@"init: X:%x, Y:%x", [Q x], [Q y]]];
        [Q begin_step];
        NSRect frame = [self bounds];
        C = new Canvas(frame.size.width, frame.size.height, -2.5, 2.5);
    }
}

- (void)stopAnimation
{
    [super stopAnimation];
    [self log: @"stopAnimation"];
}

- (void)drawRect:(NSRect)rect
{
    //[super drawRect:rect];
    //[self log: @"drawRect"];
    
    C -> clear(0.0,0.0,0.0, 0.1);
    float *hsb = CMorpher->step(0.01);
    float h = hsb[0];
    float s = hsb[1];
    float b = hsb[2];
    while( h >= 360 )
        h -= 360;
    NSColor *c = [NSColor colorWithCalibratedHue:h saturation:s brightness:b alpha:0.1];
    //[self log:[NSString stringWithFormat:@"h:%f s:%f b:%f -> r:%f g:%f b:%f",
    //           h, s, b, [c redComponent], [c greenComponent], [c blueComponent]]];
    [self log: @"--"];
    [self log: [NSString stringWithFormat:@"X:%x, Y:%x", [Q x], [Q y]]];
    for(int i=0; i<5; i++)
    {
        [self log: [NSString stringWithFormat:@"x:%f, y:%f", [Q x][i], [Q y][i]]];
    }
    C -> points(Q.NPoints, [Q x], [Q y], [c redComponent], [c greenComponent], [c blueComponent], 0.2, 1);
    C -> render();
}

- (void)point_at_x:(float)x y:(float)y color:(NSColor *)color
{
	[color set];
	NSRect r = NSMakeRect(x, y, 1.0, 1.0);
	NSRectFill(r);
}

- (void)animateOneFrame
{
	//[super animateOneFrame];
    //[self log: @"animateOneFrame"];
    [Q end_step];
    CMorpher -> step(0.01);
	[self setNeedsDisplayInRect:[self bounds]];
    [Q begin_step];
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
