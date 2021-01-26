//
//  STDSWebView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSWebView.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STDSWebView

/// Overriden to always return a set configuration object per 3DS2 security guidelines.
- (WKWebViewConfiguration *)configuration {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.preferences.javaScriptEnabled = NO;
    
    return configuration;
}

/// Overriden to do nothing per 3DS2 security guidelines.
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler {

}

- (WKNavigation *)loadExternalResourceBlockingHTMLString:(NSString *)html {
    NSString *cspMetaTag = @"<meta http-equiv=\"Content-Security-Policy\" content=\"default-src 'unsafe-inline'; img-src data:\">";
    return [self loadHTMLString:[cspMetaTag stringByAppendingString:html] baseURL:nil];
}

- (nullable NSString *)accessibilityIdentifier {
    return @"STDSWebView";
}

@end

NS_ASSUME_NONNULL_END
