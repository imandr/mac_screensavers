//
//  util.cpp
//  qexp_gpu_2
//
//  Created by Igor on 12/9/22.
//

#include "util.hpp"

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
