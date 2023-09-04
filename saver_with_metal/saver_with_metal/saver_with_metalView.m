//
//  saver_with_metalView.m
//  saver_with_metal
//
//  Created by Igor Mandrichenko on 12/5/22.
//

#import "saver_with_metalView.h"
#import <Metal/Metal.h>

@implementation saver_with_metalView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
    }
    
    FILE *log = fopen("/tmp/metal_saver.log", "w");

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLLibrary> defaultLibrary = [device newDefaultLibrary];
    fprintf(log, "default ibrary: %x\n", defaultLibrary);

    NSString* path = [[NSBundle mainBundle]
                           pathForResource:@"default" ofType:@"metallib"];
    const char *path_c = path.UTF8String;
    const char *bundle_path = [NSBundle mainBundle].bundlePath.UTF8String;


    NSArray <NSBundle*> *bundles = [NSBundle allBundles];
    int nbundles = [bundles count];
    int i;
    for( i = 0; i < nbundles; i++ )
    {
        NSBundle* b = [bundles objectAtIndex:i];
        if( [b.bundlePath containsString:@"saver_with_metal"] )
        {
            NSError *error;
            id<MTLLibrary> lib = [device newDefaultLibraryWithBundle:b error:&error];
            fprintf(log, "Library loaded from %s: %x\n", b.bundlePath.UTF8String, lib);
        }
        const char *bp = b.bundlePath.UTF8String;
        fprintf(log, "bundle: %s\n", bp);
    }
    
    NSBundle *first_bundle = [bundles objectAtIndex:0];
    NSError *error;
    id<MTLLibrary> lib = [device newDefaultLibraryWithBundle:first_bundle error:&error];

    fprintf(log, "lib:%x\n", lib);
    fclose(log);
    
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
}

- (void)animateOneFrame
{
    return;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
