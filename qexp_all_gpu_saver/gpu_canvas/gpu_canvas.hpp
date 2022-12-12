//
//  Field.hpp
//  qexp_all_gpu
//
//  Created by Igor on 12/9/22.
//

#ifndef gpu_canvas_hpp
#define gpu_canvas_hpp

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPUCanvas : NSObject
- (instancetype) initWithDevice:(id<MTLDevice>)device frame:(NSRect)frame bounds:(NSRect)bounds;
- (void) clear: (float*) color alpha:(float)alpha;
- (void) points: (int)n color:(float*)rgb alpha:(float)alpha x:(float*)x y:(float*)y;
- (unsigned int *) pixmap;
- (void) render:(float*)capture_time render_time:(float*)t;
- (NSRect) bounds;
@end

NS_ASSUME_NONNULL_END

#endif /* gpu_canvas_hpp */

