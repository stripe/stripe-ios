//
//  STPCheckoutModernViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/2/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutModernViewController.h"
#import <WebKit/WebKit.h>

@interface STPCheckoutModernViewController()<WKNavigationDelegate>
@property(weak, nonatomic)WKWebView *webView;
@end

@implementation STPCheckoutModernViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:[self initialJavascript] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    
    WKUserContentController *contentController = [WKUserContentController new];
    [contentController addUserScript:script];
    configuration.userContentController = contentController;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    [self.view addSubview:webView];
    [webView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                               options:NSLayoutFormatDirectionLeadingToTrailing
                               metrics:nil
                               views:NSDictionaryOfVariableBindings(webView)]];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:5394/v3"]]];
    webView.navigationDelegate = self;
    self.webView = webView;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    if ([url.scheme isEqualToString:@"stripecheckout"]) {
        if ([url.host isEqualToString:@"frameReady"]) {
            [webView evaluateJavaScript:@"window.checkoutJSBridge.loadOptions();"
                      completionHandler:^(id obj, NSError *error) {
                          if (error) {
                    
                          }
            }];
        }
        else if ([url.host isEqualToString:@"frameCallback"]) {
            NSString *callbackId = [[url.query componentsSeparatedByString:@"&id="] lastObject];
            if ([callbackId isEqualToString:@"2"]) {
                [webView evaluateJavaScript:@"window.checkoutJSBridge.frameCallback1();"
                          completionHandler:^(id obj, NSError *error) {
                              if (error) {
                                  
                              }
                          }];
            }
        }
        else if ([url.host isEqualToString:@"setToken"]) {
            NSString *args = [[[[[url.query componentsSeparatedByString:@"&id="] firstObject] componentsSeparatedByString:@"args="] lastObject] stringByRemovingPercentEncoding];
            NSArray *argData = [NSJSONSerialization JSONObjectWithData:[args dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:NSJSONReadingAllowFragments error:nil];
            NSString *token = argData[0][@"token"][@"id"];
            NSLog(@"Got a token! %@", token);
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        else if ([url.host isEqualToString:@"closed"]) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
