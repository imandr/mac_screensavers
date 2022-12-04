//
//  field.cpp
//  saver
//
//  Created by Igor Mandrichenko on 12/2/22.
//

#include "field.hpp"
#include <math.h>
#include <stdlib.h>
#include <morpher.hpp>

#define rnd(x) ((rand()%1000000)/1000000.0*x)

//float exp(float);

static float G(float x)
{
    return 3*(x*x*x - 1.2*x)*exp(-x*x);
}

static float F(float x)
{
    return (1-3.5*x*x)*exp(-x*x);
}

static float H(float x)
{
    return 2.3*x*exp(-x*x);
}

#define DT 0.01

static inline void step_point(float x, float y, float A, float B, float C, float D,
                         float *xout, float *yout)
{
    float x1 = G(A*x) + F(B*y);
    float y1 = H(C*y) + G(D*x);
    *xout = x1; // + (rnd(2.0)-1)*0.01;
    *yout = y1; // + (rnd(2.0)-1)*0.01;
}

void QExp::step()
{
    float *p = M->step(DT);
    float A = *p++;
    float B = *p++;
    float C = *p++;
    float D = *p++;
    int i;
    float *tmp;
    tmp = prev_x;
    prev_x = x;
    x = tmp;
    tmp = prev_y;
    prev_y = y;
    y = tmp;
    for(i=0; i<N; i++)
    {
        float x1, y1;
        if( rnd(1.0) < 0.01 )
        {
            x1 = rnd(2.0)-1.0;
            y1 = rnd(2.0)-1.0;
            for( int t = 0; t < 5; t++ )
                step_point(x1, y1, A, B, C, D, &x1, &y1);
            x[i] = x1;
            y[i] = y1;
        }
        else
            step_point(prev_x[i], prev_y[i], A, B, C, D, &(x[i]), &(y[i]));
    }
}

QExp::QExp(int n)
{
    static float pmin[4] = {0.1, 0.1, 0.1, 0.1};
    static float pmax[4] = {0.7, 0.7, 0.7, 0.7};
    M = new Morpher(4, pmin, pmax);
    
    N = n;
    x = (float*)calloc(n, sizeof(float));
    y = (float*)calloc(n, sizeof(float));
    prev_x = (float*)calloc(n, sizeof(float));
    prev_y = (float*)calloc(n, sizeof(float));
    int i;
    for( i=0; i<n; i++ )
    {
        x[i] = prev_x[i] = rnd(2.0)-1.0;
        y[i] = prev_y[i] = rnd(2.0)-1.0;
    }
}
