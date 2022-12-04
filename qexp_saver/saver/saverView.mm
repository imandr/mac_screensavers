//
//  saverView.m
//  saver
//
//  Created by Igor Mandrichenko on 11/29/22.
//

#import "saverView.h"
#include <stdio.h>
#include "field.hpp"
#include "canvas.hpp"
#import <Cocoa/Cocoa.h>

@implementation saverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
    }
    log_file = fopen("/tmp/log", "w");
    
    srand(time(NULL));
    
    static float HSBMin[3] = {0.0, 0.6, 0.8};
    static float HSBMax[3] = {1080.0, 0.8, 1.0};
    CMorpher = new Morpher(3, HSBMin, HSBMax);
    F = new QExp(10000);
    for( int t = 0; t < 10; t++ )
        F -> step();
    C = new Canvas(frame.size.width, frame.size.height, -2.5, 2.5);
    //[self log: [NSString stringWithFormat:@"Canvas created: bitmap: %x x:%x y:%y",
    //            (void*)C->Bitmap, (void*)F->x]];
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
    //[self log: @"startAnimation"];
}

- (void)stopAnimation
{
    [super stopAnimation];
    //[self log: @"stopAnimation"];
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
    C -> points(F->N, F->x, F->y, [c redComponent], [c greenComponent], [c blueComponent], 0.2);
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
    F -> step();
    CMorpher -> step(0.01);
	[self setNeedsDisplayInRect:[self bounds]];
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
    fprintf(log_file, "log: %s\n", message.UTF8String);
    fflush(log_file);
}

@end
