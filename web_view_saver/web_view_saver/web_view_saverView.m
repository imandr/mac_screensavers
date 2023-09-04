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
    FILE* log_file;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        
        [self setAnimationTimeInterval:1/30.0];
        NSString *url = NULL;
        
        // get URL from my bundle
        NSArray <NSBundle*> *bundles = [NSBundle allBundles];
        long nbundles = [bundles count];
        int i;
        for( i = 0; i < nbundles; i++ )
        {
            NSBundle* b = [bundles objectAtIndex:i];
            if( [b.bundlePath containsString:@"web_view_saver"] )
            {
                url = [b objectForInfoDictionaryKey:@"SaverURL"];
                break;
            }
        }

        [self log:url];
        URL = [NSURL URLWithString:url];
        NSURLRequest *request = [NSURLRequest requestWithURL: URL];
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        //config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
        webView = [[WKWebView alloc] initWithFrame:frame configuration:config];
        webView.navigationDelegate = self;
        [webView loadRequest:request];
    }
    return self;
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self addSubview:webView];
    [self setAutoresizesSubviews:YES];
    [webView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
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

- (void) log:(NSString*) message
{
    if( log_file != nil )
    {
        fprintf(log_file, "log: %s\n", message.UTF8String);
        fflush(log_file);
    }
}


@end
