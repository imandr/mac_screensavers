//
//  canvas.hpp
//  saver
//
//  Created by Igor Mandrichenko on 12/3/22.
//

#ifndef canvas_hpp
#define canvas_hpp

#include <stdio.h>

class Canvas
{
    CGContextRef Bitmap;
    float Scale;
    float Center;
    CGRect Rect;
    float scale_x(float x) {return (x - Center)*Scale + Rect.origin.x + Rect.size.width/2;};
    float scale_y(float y) {return (y - Center)*Scale + Rect.origin.y + Rect.size.height/2;};
public:
    Canvas(int width, int height, float xmin, float xmax);
    void clear(float r, float g, float b, float a);
    void points(int n, float *x, float *y, float r, float g, float b, float a);
    CGImageRef image();
    void render();
};

#endif /* canvas_hpp */
