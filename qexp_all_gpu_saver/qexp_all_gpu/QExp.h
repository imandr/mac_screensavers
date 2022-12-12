/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A class to manage all of the Metal objects this app creates.
*/

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

NS_ASSUME_NONNULL_BEGIN

@interface QExp : NSObject
- (instancetype) initWithDevice: (id<MTLDevice>) device npoints:(int)n;
- (void) step:(float*)params;
- (void) begin_step:(float*)params;
- (void) end_step;
- (void) flip;
- (float*) x;
- (float*) y;
@property int N;
@end

NS_ASSUME_NONNULL_END
