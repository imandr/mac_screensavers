//
//  util.hpp
//  qexp_gpu_2
//
//  Created by Igor on 12/9/22.
//

#ifndef util_hpp
#define util_hpp

#define rnd(x) (x*((float)rand())/RAND_MAX)

double millis();
void hsb_to_rgb(float h, float s, float v, float* rgb);

#endif /* util_hpp */
