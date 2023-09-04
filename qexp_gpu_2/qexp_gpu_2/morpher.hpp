//
//  morpher.hpp
//  saver
//
//  Created by Igor Mandrichenko on 12/3/22.
//

#ifndef morpher_hpp
#define morpher_hpp

#include <stdio.h>

class Morpher
{
    float *Lead;
    float *PMin;
    float *PMax;
    float *V;
    float *VMax;
public:
    int N;
    float *P;
    Morpher(int nvars, float* pmin, float* pmax);
    float *step(float dt);
};



#endif /* morpher_hpp */
