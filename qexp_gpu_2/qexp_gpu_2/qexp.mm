//
//  qexp.cpp
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/6/22.
//

#include "qexp.h"
#include "morpher.hpp"
#include "time.h"

#define rnd(x) ((rand()%1000000)/1000000.0*x)

static double millis()
{
    struct timespec spec;
    clock_gettime(CLOCK_REALTIME, &spec);
    time_t s  = spec.tv_sec;
    long ms = round(spec.tv_nsec / 1.0e6); // Convert nanoseconds to milliseconds
    if (ms > 999) {
        s++;
        ms = 0;
    }
    return (double)s + ((double)ms)/1000;
}

static inline float G(float x)
{
    return 3*(x*x*x - 1.2*x)*exp(-x*x);
}

static inline float F(float x)
{
    return (1-3.5*x*x)*exp(-x*x);
}

static inline float H(float x)
{
    return 2.3*x*exp(-x*x);
}

static inline void step(float x, float y, float *params, float *xout, float *yout)
{
    float A = params[0];
    float B = params[1];
    float C = params[2];
    float D = params[3];
    
    *xout = G(x*A) + F(y*B);
    *yout = G(y*C) + F(x*D);
}

@implementation QExp
{
    float *X;
    float *Y;
    float *X_prev;
    float *Y_prev;
    Morpher *PMorpher;
}

- (instancetype) initForPoints: (int) n
{
    self = [super init];
    if (self)
    {
        _NPoints = n;
        static float pmin[4] = {0.1, 0.1, 0.1, 0.1};
        static float pmax[4] = {0.7, 0.7, 0.7, 0.7};
        PMorpher = new Morpher(4, pmin, pmax);
        X = (float*)calloc(n, sizeof(float));
        Y = (float*)calloc(n, sizeof(float));
        X_prev = (float*)calloc(n, sizeof(float));
        Y_prev = (float*)calloc(n, sizeof(float));
        
        int i;
        for( i = 0; i < n; i++ )
        {
            X_prev[i] = rnd(2)-1;
            Y_prev[i] = rnd(2)-1;
        }
        
        [self begin_step];
    }
    return self;
}

- (void) begin_step
{
    float *params = PMorpher -> step(0.01);
    int i;
    for( i=0; i<_NPoints; i++ )
        step(X_prev[i], Y_prev[i], params, &X[i], &Y[i]);
}

- (void) end_step
{
    float *tmp;
    
    tmp = X;
    X = X_prev;
    X_prev = tmp;
    
    tmp = Y;
    Y = Y_prev;
    Y_prev = tmp;
}

- (float *) x
{
    return X_prev;
}
- (float *) y
{
    return Y_prev;
}

@end
