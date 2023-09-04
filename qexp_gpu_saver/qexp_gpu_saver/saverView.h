//
//  saverView.h
//  saver
//
//  Created by Igor Mandrichenko on 11/29/22.
//

#import <ScreenSaver/ScreenSaver.h>
#include <stdio.h>
#include "canvas.hpp"
#include "morpher.hpp"
#import "qexp_gpu.h"


@interface saverView : ScreenSaverView
{
    FILE* log_file;
    Canvas *C;
    Morpher *CMorpher;      // Color morpher
    QExp *Q;
}

- (void) log:(NSString*) message;
- (void) point_at_x:(float)x y:(float)y color:(NSColor *)color;

@end
