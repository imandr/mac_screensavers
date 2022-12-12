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
#include "util.hpp"


#define rnd(x) ((rand()%1000000)/1000000.0*x)

#define BITS_PER_COLOR  8
#define BYTES_PER_PIXEL (((int)((BITS_PER_COLOR+7)/8))*4)

Canvas_offscreen::Canvas_offscreen(int width, int height, float xmin, float xmax)
{
    float xscale = width/(xmax - xmin);
    float yscale = height/(xmax - xmin);
    Scale = xscale < yscale ? xscale : yscale;
    Center = (xmax + xmin)/2;
    int bytes_per_row = width * BYTES_PER_PIXEL;
    Pixels = (unsigned char*)malloc(bytes_per_row * height);
    //CGColorSpaceRef color_space = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    //FILE *log = fopen("/tmp/canvas.log", "w");
    //fprintf(log, "data:%x w:%d h:%d bytes_per_row:%d color_space:%x\n",
    //        bitmap_data, width, height, bytes_per_row, color_space);
    Bitmap = CGBitmapContextCreate(Pixels, width, height,
                                   BITS_PER_COLOR, bytes_per_row,
                                   color_space,
                                   kCGImageAlphaPremultipliedLast);
    //fprintf(log, "bitmap:%x\n", Bitmap);
    //fclose(log);
    Rect = CGRectMake(0, 0, width, height);
    clear(0,0,0,1.0);
}

void Canvas_offscreen::clear(float r, float g, float b, float a)
{
    CGContextSetRGBFillColor(Bitmap, r, g, b, a);
    CGContextFillRect(Bitmap, Rect);
}

#define __blend(old, new, alpha) (\
    (int)(0.5 + \
        (\
            ((float)new * alpha) + ((float)old/255.0 * (1.0-alpha))\
        )*255.0\
    )\
)

#define blend(old, new, alpha) (new)

#if 1
void Canvas_offscreen::points(int n, float *x, float *y, float r, float g, float b, float a, float size)
{
    for( int i=0; i<n; i++)
    {
        unsigned char* pixel = pixel_pointer(scale_x(x[i])-size/2, scale_y(y[i])-size/2);
        pixel[0] = blend(pixel[0], r, a);
        pixel[1] = blend(pixel[1], g, a);
        pixel[2] = blend(pixel[2], b, a);
        pixel[3] = 0xff;
    }
}

#else

void Canvas_offscreen::points(int n, float *x, float *y, float r, float g, float b, float a, float size)
{
    CGRect *rects = (CGRect *)calloc(n, sizeof(CGRect));
    CGRect *rect;
    int i;
    for( i = 0, rect = rects; i < n; i++, rect++ )
    {
        rect->size.width = rect->size.height = size;
        rect->origin.x = scale_x(x[i])-size/2;
        rect->origin.y = scale_y(y[i])-size/2;
    }
    CGContextSetRGBFillColor(Bitmap, r, g, b, a);
    CGContextFillRects(Bitmap, rects, n);
    free(rects);
}
#endif

CGImageRef Canvas_offscreen::image()
{
    return CGBitmapContextCreateImage(Bitmap);
}

void Canvas_offscreen::render(float *capture_time, float *render_time)
{
    double t0 = millis();
    CGImageRef img = image();
    *capture_time = millis() - t0;
    t0 = millis();
    CGContextRef view_context = [[NSGraphicsContext currentContext] CGContext];
    CGContextDrawImage(view_context, Rect, img);
    *render_time = millis() - t0;
    CGImageRelease(img);
}
