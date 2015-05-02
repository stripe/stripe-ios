//
//  STPIOSCheckoutWebViewAdapter.m
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import "STPIOSCheckoutWebViewAdapter.h"
#import "STPStrictURLProtocol.h"
#import "STPCheckoutDelegate.h"

@implementation STPIOSCheckoutWebViewAdapter

@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _webView.delegate = self;
        _webView.keyboardDisplayRequiresUserAction = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [NSURLProtocol registerClass:[STPStrictURLProtocol class]]; });
    }
    return self;
}

- (void)dealloc {
    _webView.delegate = nil;
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView loadRequest:request];
}

- (NSString *)evaluateJavaScript:(NSString *)js {
    return [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(__unused UIWebView *)webView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate checkoutAdapterDidStartLoad:self];
    });
}

- (BOOL)webView:(__unused UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    switch (navigationType) {
    case UIWebViewNavigationTypeLinkClicked: {
        if ([url.host isEqualToString:checkoutHost]) {
            if ([url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
                [[UIApplication sharedApplication] openURL:url];
                return NO;
            }
            return YES;
        }
        return NO;
    }
    case UIWebViewNavigationTypeOther: {
        if ([url.scheme isEqualToString:checkoutRPCScheme]) {
            NSString *event = url.host;
            NSString *path = [url.path componentsSeparatedByString:@"/"][1];
            NSDictionary *payload = @{};
            if (path != nil) {
                payload = [NSJSONSerialization JSONObjectWithData:[path dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate checkoutAdapter:self didTriggerEvent:event withPayload:payload];
            });
            return NO;
        }
        return YES;
    }
    default:
        // add tracking
        return NO;
    }
}

- (void)webViewDidFinishLoad:(__unused UIWebView *)webView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate checkoutAdapterDidFinishLoad:self];
    });
}

- (void)webView:(__unused UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // Cancellation callbacks are handled directly by the webview, so no need to catch them here.
    if ([error code] != NSURLErrorCancelled) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate checkoutAdapter:self didError:error];
        });
    }
}

@end

#endif
