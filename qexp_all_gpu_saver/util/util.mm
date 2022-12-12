//
//  util.cpp
//  qexp_gpu_2
//
//  Created by Igor on 12/9/22.
//

#include "util.h"

#include <time.h>

double millis()
{
    struct timespec spec;
    clock_gettime(CLOCK_REALTIME, &spec);
    time_t s  = spec.tv_sec;
    double f = spec.tv_nsec / 1.0e9;
    if (f >= 1) {
        s++;
        f = 0.0;
    }
    return (double)s + f;
}

void hsb_to_rgb(float h, float s, float v, float* rgb)
{
    //
    // HSB and RGB are all normalized to [0,1.0]
    //

    if (s == 0)
    {
        rgb[0] = rgb[1] = rgb[2] = v;
        return;
    }

    h = h - (int)h;
    
    float t1 = v;
    float t2 = (1.0 - s) * v;
    float h6 = h*6.0;
    float hr = h6 - (int)h6;
    
    float t3 = (t1 - t2) * hr;
    float r, g, b;

    if (h6 < 1) { r = t1; b = t2; g = t2 + t3; }
    else if (h6 < 2) { g = t1; b = t2; r = t1 - t3; }
    else if (h6 < 3) { g = t1; r = t2; b = t2 + t3; }
    else if (h6 < 4) { b = t1; r = t2; g = t1 - t3; }
    else if (h6 < 5) { b = t1; g = t2; r = t2 + t3; }
    else if (h6 < 6) { r = t1; g = t2; b = t1 - t3; }
    else { r = 0; g = 0; b = 0; }

    rgb[0] = r;
    rgb[1] = g;
    rgb[2] = b;
}


