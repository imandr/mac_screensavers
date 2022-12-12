//
//  morpher.cpp
//  saver
//
//  Created by Igor Mandrichenko on 12/3/22.
//

#include "morpher.hpp"
#include <math.h>

#define rnd(x) ((rand()%1000000)/1000000.0*x)

#define M 0.95

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
        float v = V[i] + (rnd(2.0)-1)*VMax[i]*0.5;
        if( v > VMax[i] )   v =  VMax[i];
        if( v < -VMax[i] )  v = -VMax[i];
        float p = Lead[i] + v*dt;
        if( p > PMax[i] || p < PMin[i] )
        {
            v = -v/2;
            p = Lead[i] + v*dt;
        }
        V[i] = v;
        Lead[i] = p;
        P[i] += (p-P[i])*(1-M);
    }
    return P;
}

static void hsb_to_rgb(float h, float s, float v, float* rgb)
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

static float HSBMin[3] = {0.0, 0.2, 0.8};
static float HSBMax[3] = {3.0, 0.9, 1.0};

HSBMorpher::HSBMorpher()
: Morpher(3, HSBMin, HSBMax)
{
}

void HSBMorpher::rgb(float *out)
{
    hsb_to_rgb(P[0], P[1], P[2], out);
}

void HSBMorpher::hsb(float *out)
{
    out[0] = P[0];
    out[1] = P[1];
    out[2] = P[2];
}
