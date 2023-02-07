//
//  web_view_saverView.h
//  web_view_saver
//
//  Created by Igor on 12/30/22.
//

#import <ScreenSaver/ScreenSaver.h>
#import <WebKit/WebKit.h>

@interface web_view_saverView : ScreenSaverView <WKNavigationDelegate>
{
    NSURL *URL;
}


@end
