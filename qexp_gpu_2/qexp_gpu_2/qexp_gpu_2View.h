//
//  qexp_gpu_2View.h
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/5/22.
//

#import <ScreenSaver/ScreenSaver.h>
#include "canvas.hpp"
#include "morpher.hpp"
#import "qexp.h"

@interface qexp_gpu_2View : ScreenSaverView
{
    FILE* log_file;
    Canvas *C;
    Morpher *CMorpher;      // Color morpher
    QExp *Q;
}

@end
