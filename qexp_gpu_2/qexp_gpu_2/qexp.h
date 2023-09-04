//
//  qexp.hpp
//  qexp_gpu_2
//
//  Created by Igor Mandrichenko on 12/6/22.
//

#ifndef qexp_hpp
#define qexp_hpp

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface QExp : NSObject
- (instancetype) initForPoints: (int) n;
- (void) begin_step;
- (void) end_step;
- (float *)x;
- (float *)y;
@property int NPoints;
@property double Elapsed;
@end

NS_ASSUME_NONNULL_END

#endif /* qexp_hpp */
