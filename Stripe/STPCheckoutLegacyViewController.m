//
//  STPCheckoutLegacyViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/2/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutLegacyViewController.h"

@interface STPCheckoutLegacyViewController()<UIWebViewDelegate>
@property(weak, nonatomic)UIWebView *webView;
@end

@implementation STPCheckoutLegacyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIWebView *webView = [UIWebView new];
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
    webView.delegate = self;
    self.webView = webView;
}



#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [webView stringByEvaluatingJavaScriptFromString:[self initialJavascript]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if ([url.scheme isEqualToString:@"stripecheckout"]) {
        if ([url.host isEqualToString:@"frameReady"]) {
            [webView stringByEvaluatingJavaScriptFromString:@"window.checkoutJSBridge.loadOptions();"];
        }
        else if ([url.host isEqualToString:@"frameCallback"]) {
            NSString *callbackId = [[url.query componentsSeparatedByString:@"&id="] lastObject];
            if ([callbackId isEqualToString:@"2"]) {
                [webView stringByEvaluatingJavaScriptFromString:@"window.checkoutJSBridge.frameCallback1();"];
            }
        }
        else if ([url.host isEqualToString:@"setToken"]) {
            NSString *args = [[[[[url.query componentsSeparatedByString:@"&id="] firstObject] componentsSeparatedByString:@"args="] lastObject] stringByRemovingPercentEncoding];
            NSArray *argData = [NSJSONSerialization JSONObjectWithData:[args dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:NSJSONReadingAllowFragments error:nil];
            NSString *token = argData[0][@"token"][@"id"];
            NSLog(@"Got a token! %@", token);
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        return NO;
    }
    return YES;
}

@end
