//
//  saverView.h
//  saver
//
//  Created by Igor Mandrichenko on 11/29/22.
//

#import <ScreenSaver/ScreenSaver.h>
#include <stdio.h>
#include "field.hpp"
#include "canvas.hpp"
#include "morpher.hpp"

@interface saverView : ScreenSaverView
{
    FILE* log_file;
    QExp *F;
    Canvas *C;
    Morpher *CMorpher;      // Color morpher
}

- (void) log:(NSString*) message;
- (void) point_at_x:(float)x y:(float)y color:(NSColor *)color;

@end
