//
//  CanvasTestView.m
//  test_view
//
//  Created by Igor on 12/10/22.
//

#import "CanvasTestView.h"
#import "gpu_canvas.hpp"
#include <stdlib.h>

#define rnd(x) ((rand()%1000000)/1000000.0*x)


@implementation CanvasTestView
{
    GPUCanvas *Canvas;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    int n = 1000000;
    int i;
    float points_x[n];
    float points_y[n];
    float red[3] = {1.0, 0.2, 0.2};
    float black[3] = {0.0, 0.0, 0.0};
    float green[3] = {0.2, 1.0, 0.2};
    
    
    CGImageRef img = CGImageCreateWithImageInRect(CGImageRef image, CGRect rect);
    
    [Canvas clear:black alpha:1.0];
    NSRect red_rect = NSInsetRect([Canvas bounds], 0.2, 0.4);
    NSRect green_rect = NSInsetRect([Canvas bounds], 0.4, 0.2);
    for( i=0; i<n; i++ )
    {
        points_x[i] = rnd(red_rect.size.width) + red_rect.origin.x;
        points_y[i] = rnd(red_rect.size.height) + red_rect.origin.y;
    }
    [Canvas points:n color:red alpha:0.5 x:points_x y:points_y];
    for( i=0; i<n; i++ )
    {
        points_x[i] = rnd(green_rect.size.width) + green_rect.origin.x;
        points_y[i] = rnd(green_rect.size.height) + green_rect.origin.y;
    }
    [Canvas points:n color:green alpha:0.1 x:points_x y:points_y];
    float t0, t1;
    [Canvas render:&t0 render_time:&t1];

    // Drawing code here.
}

- (void) init_with_frame:(NSRect)frame
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    NSRect bounds;
    bounds.origin.x = bounds.origin.y = -2.0;
    bounds.size.width = bounds.size.height = 4.0;
    Canvas = [GPUCanvas alloc];
    //Canvas = [Canvas initWithDevice:device size:frame.size bounds:bounds];
    Canvas  = [Canvas initWithDevice:device frame:frame bounds:bounds];
    float black[3] = {0.0, 0.0, 0.0};
    
    [Canvas clear:black alpha:1.0];
    
    
#if 0
    NSTextField* t = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 100, 40)];
    [self addSubview:t];
    t.backgroundColor = [NSColor blackColor];
    t.textColor = [NSColor whiteColor];
    [t.cell setStringValue:@"Hello there"];
#endif
}

- (void) awakeFromNib
{
    [self init_with_frame:self.frame];
}

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self init_with_frame:frame];
    }
    return self;
}


@end
