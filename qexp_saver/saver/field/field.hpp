//
//  field.hpp
//  saver
//
//  Created by Igor Mandrichenko on 12/2/22.
//

#ifndef field_hpp
#define field_hpp

#include <stdio.h>
#include "morpher.hpp"

class QExp {
    Morpher *M;
public:
    int N;
    float *x;
    float *y;
    float *prev_x;
    float *prev_y;

    QExp(int n);
    void step();
};

#endif /* field_hpp */
