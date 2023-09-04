//
//  qexp_gpu.h
//  saver
//
//  Created by Igor Mandrichenko on 12/4/22.
//

#ifndef qexp_gpu_h
#define qexp_gpu_h

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface QExpGPU : NSObject
- (instancetype) initForPoints: (int) n;
- (void) begin_step;
- (void) end_step;
- (float *)x;
- (float *)y;
@property int NPoints;
@property double Elapsed;
@end

NS_ASSUME_NONNULL_END

#endif /* qexp_gpu_h */
