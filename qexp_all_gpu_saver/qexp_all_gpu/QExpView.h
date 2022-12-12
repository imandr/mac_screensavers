//
//  qexp_gpu_2View.h
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/5/22.
//

#import <ScreenSaver/ScreenSaver.h>
#include "gpu_canvas.hpp"
#include "morpher.hpp"
#import "QExp.h"

@interface QExpView : ScreenSaverView
{
    FILE* log_file;
    GPUCanvas *C;
    HSBMorpher *CMorpher;      // Color morpher
    Morpher *PMorpher;      // Params morpher
    QExp *Q;
}

@end
