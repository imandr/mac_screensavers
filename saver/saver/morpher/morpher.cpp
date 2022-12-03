//
//  morpher.cpp
//  saver
//
//  Created by Igor Mandrichenko on 12/3/22.
//

#include "morpher.hpp"
#include <math.h>

#define rnd(x) ((rand()%1000000)/1000000.0*x)

#define M 0.9

Morpher::Morpher(int n, float* pmin, float *pmax)
{
    N = n;
    PMin = pmin;
    PMax = pmax;
    P = (float*)calloc(n, sizeof(float));
    V = (float*)calloc(n, sizeof(float));
    VMax = (float*)calloc(n, sizeof(float));
    Lead = (float*)calloc(n, sizeof(float));
    int i;
    for( i=0; i<n; i++ )
    {
        float dp = PMax[i] - PMin[i];
        Lead[i] = P[i] = PMin[i] + rnd(dp);
        VMax[i] = dp/20;
        V[i] = (rnd(2.0) - 1)*VMax[i];
    }
}

float *Morpher::step(float dt)
{
    int i;
    for( i = 0; i < N; i++ )
    {
        float v = V[i] + (rnd(2.0)-1)*VMax[i]*0.01;
        if( v > VMax[i] )   v = VMax[i];
        if( v < -VMax[i] )  v = -VMax[i];
        float p = Lead[i] + v*dt;
        if( p > PMax[i] || p < PMin[i] )
        {
            v = -v;
            p = Lead[i] + v*dt;
        }
        V[i] = v;
        Lead[i] = p;
        P[i] += (p-P[i])*(1-M);
    }
    return P;
}
