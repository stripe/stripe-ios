//
//  STPOSXCheckoutWebViewAdapter.m
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE

#import "STPOSXCheckoutWebViewAdapter.h"
#import "STPStrictURLProtocol.h"
#import "STPCheckoutWebViewAdapter.h"
#import "STPCheckoutDelegate.h"

#ifdef MAC_OS_X_VERSION_10_11
@interface STPOSXCheckoutWebViewAdapter()<WebFrameLoadDelegate, WebPolicyDelegate, WebResourceLoadDelegate>
@end
#endif

@implementation STPOSXCheckoutWebViewAdapter

@synthesize delegate;

- (instancetype)init {
    self = [super init];
    if (self) {
        _webView = [[WebView alloc] initWithFrame:CGRectZero];
        _webView.drawsBackground = NO;
        _webView.frameLoadDelegate = self;
        _webView.policyDelegate = self;
        _webView.resourceLoadDelegate = self;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [NSURLProtocol registerClass:[STPStrictURLProtocol class]]; });
    }
    return self;
}

- (void)dealloc {
    _webView.frameLoadDelegate = nil;
    _webView.policyDelegate = nil;
    _webView.resourceLoadDelegate = nil;
}

- (void)loadRequest:(NSURLRequest *)request {
    [self.webView.mainFrame loadRequest:request];
}

- (NSString *)evaluateJavaScript:(NSString *)js {
    return [self.webView.windowScriptObject evaluateWebScript:js];
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading:nil];
    }
}

#pragma mark - ResourceLoadDelegate
- (NSURLRequest *)webView:(__unused WebView *)sender
                 resource:(__unused id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(__unused NSURLResponse *)redirectResponse
           fromDataSource:(__unused WebDataSource *)dataSource {
    return request;
}

- (id)webView:(__unused WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(__unused WebDataSource *)dataSource {
    return request.URL;
}

- (void)webView:(__unused WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    if ([identifier isEqual:dataSource.initialRequest.URL]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate checkoutAdapter:self didError:error];
        });
    }
}

#pragma mark - WebPolicyDelegate
- (void)webView:(__unused WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(__unused WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSURL *url = request.URL;
    if ([NSURLProtocol propertyForKey:STPStrictURLProtocolRequestKey inRequest:request] != nil) {
        [listener use];
        return;
    }
    WebNavigationType navigationType = [actionInformation[WebActionNavigationTypeKey] integerValue];
    switch (navigationType) {
        case WebNavigationTypeLinkClicked: {
            if ([url.host isEqualToString:checkoutHost]) {
                if ([url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
                    [[NSWorkspace sharedWorkspace] openURL:url];
                    [listener ignore];
                    return;
                }
                [listener use];
                return;
            }
            [listener ignore];
            break;
        }
        case WebNavigationTypeOther: {
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
                [listener ignore];
                return;
            }
            [listener use];
            break;
        }
        default:
            // add tracking
            [listener ignore];
            break;
    }
}

#pragma mark - WebFrameLoadDelegate
- (void)webView:(__unused WebView *)sender didStartProvisionalLoadForFrame:(__unused WebFrame *)frame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate checkoutAdapterDidStartLoad:self];
    });
}

- (void)webView:(__unused WebView *)sender didFailLoadWithError:(NSError *)error
       forFrame:(__unused WebFrame *)frame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate checkoutAdapter:self didError:error];
    });
}

- (void)webView:(__unused WebView *)sender didFinishLoadForFrame:(__unused WebFrame *)frame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate checkoutAdapterDidFinishLoad:self];
    });
}

@end

#endif
