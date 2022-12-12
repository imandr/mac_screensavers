//
//  canvas2.cpp
//  qexp_gpu_2
//
//  Created by Igor on 12/8/22.
//

#import <ScreenSaver/ScreenSaver.h>
#include "canvas2.hpp"
#include <stdlib.h>
#include <stdio.h>
#import <Cocoa/Cocoa.h>
#include "util.hpp"


#define rnd(x) ((rand()%1000000)/1000000.0*x)

#define BITS_PER_COLOR  8
#define BYTES_PER_PIXEL (((int)((BITS_PER_COLOR+7)/8))*4)

Canvas::Canvas(int width, int height, float xmin, float xmax)
{
    float xscale = width/(xmax - xmin);
    float yscale = height/(xmax - xmin);
    Scale = xscale < yscale ? xscale : yscale;
    Center = (xmax + xmin)/2;
    int bytes_per_row = width * BYTES_PER_PIXEL;
    void *bitmap_data = calloc(bytes_per_row * height, 1);
    CGColorSpaceRef color_space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    //FILE *log = fopen("/tmp/canvas.log", "w");
    //fprintf(log, "data:%x w:%d h:%d bytes_per_row:%d color_space:%x\n",
    //        bitmap_data, width, height, bytes_per_row, color_space);
    Bitmap = CGBitmapContextCreate(bitmap_data, width, height, BITS_PER_COLOR, bytes_per_row,
                                   color_space,
                                   kCGImageAlphaPremultipliedLast);
    //fprintf(log, "bitmap:%x\n", Bitmap);
    //fclose(log);
    Rect = CGRectMake(0, 0, width, height);
    clear(0,0,0,1.0);
}

void Canvas::clear(float r, float g, float b, float a)
{
    CGContextRef view_context = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetRGBFillColor(Bitmap, r, g, b, a);
    CGContextFillRect(view_context, Rect);
}

void Canvas::points(int n, float *x, float *y, float r, float g, float b, float a, float size)
{
    CGContextRef view_context = [[NSGraphicsContext currentContext] CGContext];
    CGRect *rects = (CGRect *)calloc(n, sizeof(CGRect));
    CGRect *rect;
    int i;
    for( i = 0, rect = rects; i < n; i++, rect++ )
    {
        rect->size.width = rect->size.height = size;
        rect->origin.x = scale_x(x[i])-size/2;
        rect->origin.y = scale_y(y[i])-size/2;
    }
    CGContextSetRGBFillColor(view_context, r, g, b, a);
    CGContextFillRects(view_context, rects, n);
    free(rects);
}

CGImageRef Canvas::image()
{
    return CGBitmapContextCreateImage(Bitmap);
}

void Canvas::render()
{
}
