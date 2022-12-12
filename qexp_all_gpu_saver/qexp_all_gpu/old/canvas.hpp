//
//  canvas.hpp
//  saver
//
//  Created by Igor Mandrichenko on 12/3/22.
//

#ifndef canvas_hpp
#define canvas_hpp

#include <stdio.h>

class Canvas_offscreen
{
    CGContextRef Bitmap;
    unsigned char* Pixels;
    float Scale;
    float Center;
    CGRect Rect;
    int width, height, bytes_per_row, bytes_per_pixel;
    float scale_x(float x) {return (x - Center)*Scale + Rect.origin.x + Rect.size.width/2;};
    float scale_y(float y) {return (y - Center)*Scale + Rect.origin.y + Rect.size.height/2;};
    
    unsigned char* pixel_pointer(int ix, int iy)
    {
        return Pixels + iy*bytes_per_row + ix*bytes_per_pixel;
    }

    
public:
    Canvas_offscreen(int width, int height, float xmin, float xmax);
    void clear(float r, float g, float b, float a);
    void points(int n, float *x, float *y, float r, float g, float b, float a, float size);
    CGImageRef image();
    void render(float *, float*);
};

#endif /* canvas_hpp */
