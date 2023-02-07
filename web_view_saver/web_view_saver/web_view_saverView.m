//
//  web_view_saverView.m
//  web_view_saver
//
//  Created by Igor on 12/30/22.
//

#import "web_view_saverView.h"


@implementation web_view_saverView
{
    WKWebView *webView;
    bool loaded;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/30.0];
        URL = [NSURL URLWithString:@"https://imandr.github.io/attractors/saver.html"];
        NSURLRequest *request = [NSURLRequest requestWithURL: URL];
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
        webView.navigationDelegate = self;
        [webView loadRequest:request];
    }
    return self;
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self addSubview:webView];
    [self setNeedsDisplay:YES];
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
    [webView drawRect:rect];
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
