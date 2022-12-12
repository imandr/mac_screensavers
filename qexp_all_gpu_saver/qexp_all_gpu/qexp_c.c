//
//  qexp_c.c
//  MetalComputeBasic
//
//  Created by Igor Mandrichenko on 12/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#include "qexp_c.h"
#include <math.h>

#define G(x) ((3 * (x)*(x)*(x) - 1.2*(x)) * exp(-(x)*(x)))
#define F(x) ((1-3.5*(x)*(x)*(x)) * exp(-(x)*(x)))
#define H(x) (2.3 * (x) * exp(-(x)*(x)))

void qexp_c(int n,
            const float* in_x, const float* in_y,
            const float* params,
            float* out_x, float* out_y)
{
    int index;
    for( index = 0; index < n; index++ )
    {
        out_x[index] = G(params[0]*in_x[index]) + H(params[1]*in_y[index]);
        out_y[index] = G(params[2]*in_y[index]) + F(params[3]*in_x[index]);
    }
}
