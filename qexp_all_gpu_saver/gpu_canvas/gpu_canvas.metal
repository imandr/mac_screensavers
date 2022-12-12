//
//  field.metal
//  qexp_all_gpu
//
//  Created by Igor on 12/9/22.
//

#include <metal_stdlib>
using namespace metal;

#define blend(old, new, alpha) ((old)*(1.0-(alpha)) + (new)*(alpha))

kernel void clear(device const float* rgb,
                  device const float* alpha,
                  device float* r_pixels,
                  device float* g_pixels,
                  device float* b_pixels,
                  uint index [[thread_position_in_grid]]
                  )
{
    float a = *alpha;
    r_pixels[index] = blend(r_pixels[index], rgb[0], a);
    g_pixels[index] = blend(g_pixels[index], rgb[1], a);
    b_pixels[index] = blend(b_pixels[index], rgb[2], a);
}

kernel void pixmap(
                      device const float* r_pixels,
                      device const float* g_pixels,
                      device const float* b_pixels,
                      device unsigned int* bitmap,
                      uint index [[thread_position_in_grid]]
                  )
{
    unsigned char r = (int)(r_pixels[index]*255.0 + 0.5);
    unsigned char g = (int)(g_pixels[index]*255.0 + 0.5);
    unsigned char b = (int)(b_pixels[index]*255.0 + 0.5);
    bitmap[index] = 0xFF000000 | (r << 16) | (g << 8) | b;
}

kernel void __points(device const float* rgb,
                   device const float* alpha,
                   device const float* origin,
                   device const float* range,
                   device const int* bounds,            // origin.x, origin.y, width, height
                   device const float* x,
                   device const float* y,
                   device float* r_pixels,
                   device float* g_pixels,
                   device float* b_pixels,
                   uint index [[thread_position_in_grid]]
                  )
{
    float a = *alpha;
    float xp = x[index];
    float yp = y[index];

    int ix = (int)((xp - origin[0])/range[0]*bounds[0]);
    int iy = (int)((yp - origin[1])/range[1]*bounds[1]);
    
    int i = ix + iy * bounds[0];
    
    r_pixels[i] = blend(r_pixels[i], rgb[0], a);
    g_pixels[i] = blend(g_pixels[i], rgb[1], a);
    b_pixels[i] = blend(b_pixels[i], rgb[2], a);
}

static constant float K[3][3] = {
    {   0.05, 0.1, 0.05   },
    {   0.1, 1.0, 0.1   },
    {   0.05, 0.1, 0.05   }
};


kernel void points(device const float* rgb,
                   device const float* alpha,
                   device const float* origin,
                   device const float* range,
                   device const int* bounds,            // origin.x, origin.y, width, height
                   device const float* x,
                   device const float* y,
                   device float* r_pixels,
                   device float* g_pixels,
                   device float* b_pixels,
                   uint index [[thread_position_in_grid]]
                  )
{
    float a = *alpha;
    float xp = x[index];
    float yp = y[index];

    int ix = (int)((xp - origin[0])/range[0]*bounds[0]);
    int iy = (int)((yp - origin[1])/range[1]*bounds[1]);
    
    for( int i = 0; i < 3; i++ )
    {
        int ii = ix + i;
        if( ii >= 0 && ii < bounds[0] )
        {
            constant float *krow = K[i];
            for( int j = 0; j < 3; j++ )
            {
                int jj = iy + j;
                if( jj >= 0 && jj < bounds[1] )
                {
                    int k = ii + jj * bounds[0];
                    float m = krow[j];
                    r_pixels[k] = blend(r_pixels[k], rgb[0], a*m);
                    g_pixels[k] = blend(g_pixels[k], rgb[1], a*m);
                    b_pixels[k] = blend(b_pixels[k], rgb[2], a*m);
                }
            }
        }
    }
}

