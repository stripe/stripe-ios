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

- (void)evaluateJavaScript:(NSString *)js {
    [self.webView.windowScriptObject evaluateWebScript:js];
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading:nil];
    }
}

#pragma mark - ResourceLoadDelegate
- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource {
    return request;
}

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource {
    return request.URL;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    if ([identifier isEqual:dataSource.initialRequest.URL]) {
        [self.delegate checkoutAdapter:self didError:error];
    }
}

#pragma mark - WebPolicyDelegate
- (void)webView:(WebView *)webView
decidePolicyForNavigationAction:(NSDictionary *)actionInformation
        request:(NSURLRequest *)request
          frame:(WebFrame *)frame
decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSURL *url = request.URL;
    if ([STPStrictURLProtocol propertyForKey:STPStrictURLProtocolRequestKey inRequest:request] != nil) {
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
            if (url.path && [url.path rangeOfString:checkoutURLPathIdentifier].location != NSNotFound) {
                NSRange checkoutURLRange = [url.path rangeOfString:checkoutURLPathIdentifier];
                NSString *substring = [url.path substringFromIndex:(checkoutURLRange.location + checkoutURLRange.length)];
                if ([substring hasPrefix:@"/"]) {
                    substring = [substring substringFromIndex:1];
                }
                NSArray *properties = [substring componentsSeparatedByString:@"/"];
                if (properties.count) {
                    NSString *event = properties.firstObject;
                    NSDictionary *payload = nil;
                    if (properties.count > 1) {
                        payload = [NSJSONSerialization JSONObjectWithData:[properties[1] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
                    }
                    [self.delegate checkoutAdapter:self didTriggerEvent:event withPayload:payload];
                }
                
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
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame {
    [self.delegate checkoutAdapterDidStartLoad:self];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
    [self.delegate checkoutAdapter:self didError:error];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    [self.delegate checkoutAdapterDidFinishLoad:self];
}

@end

#endif
