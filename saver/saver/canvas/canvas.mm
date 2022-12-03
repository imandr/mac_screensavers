//
//  canvas.cpp
//  saver
//
//  Created by Igor Mandrichenko on 12/3/22.
//

#import <ScreenSaver/ScreenSaver.h>
#include "canvas.hpp"
#include <stdlib.h>
#include <stdio.h>
#import <Cocoa/Cocoa.h>

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
    CGContextSetRGBFillColor(Bitmap, r, g, b, a);
    CGContextFillRect(Bitmap, Rect);
}

void Canvas::points(int n, float *x, float *y, float r, float g, float b, float a)
{
    CGRect *rects = (CGRect *)calloc(n, sizeof(CGRect));
    CGRect *rect;
    int i;
    for( i = 0, rect = rects; i < n; i++, rect++ )
    {
        float point_size = 1.0 + rnd(1.0)*rnd(1.0);
        rect->size.width = rect->size.height = 1.0;
        rect->origin.x = scale_x(x[i]);
        rect->origin.y = scale_y(y[i]);
    }
    CGContextSetRGBFillColor(Bitmap, r, g, b, a);
    CGContextFillRects(Bitmap, rects, n);
    free(rects);
}

CGImageRef Canvas::image()
{
    return CGBitmapContextCreateImage(Bitmap);
}

void Canvas::render()
{
    CGImageRef img = image();
    CGContextRef view_context = [[NSGraphicsContext currentContext] CGContext];
    CGContextDrawImage(view_context, Rect, img);
    CGImageRelease(img);
}
