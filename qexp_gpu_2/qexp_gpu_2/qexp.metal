//
//  qexp.metal
//  saver
//
//  Created by Igor Mandrichenko on 12/4/22.
//

#include <metal_stdlib>
using namespace metal;

#define G(x) (3 * (x)*(x)*(x) - 1.2*(x) * exp(-(x)*(x)))
#define F(x) (1-3.5*(x)*(x)*(x) * exp(-(x)*(x)))
#define H(x) (2.3 * (x) * exp(-(x)*(x)))

/// This is a Metal Shading Language (MSL) function equivalent to the add_arrays() C function, used to perform the calculation on a GPU.
kernel void qexp_step(device const float* in_x, device const float* in_y,
                device const float* params,
                device float* out_x,
                device float* out_y,
                uint index [[thread_position_in_grid]])
{
    out_x[index] = G(params[0]*in_x[index]) + F(params[1]*in_y[index]);
    out_y[index] = G(params[2]*in_y[index]) + F(params[3]*in_x[index]);
    //out_x[index] = G(in_x[index]) + F(in_y[index]);
    //out_y[index] = G(in_y[index]) + F(in_x[index]);
}
