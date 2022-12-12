//
//  qexp_c.h
//  MetalComputeBasic
//
//  Created by Igor Mandrichenko on 12/8/22.
//  Copyright © 2022 Apple. All rights reserved.
//

#ifndef qexp_c_h
#define qexp_c_h

#include <stdio.h>
void qexp_c(int n,
            const float* in_x, const float* in_y,
            const float* params,
            float* out_x, float* out_y);
#endif /* qexp_c_h */
