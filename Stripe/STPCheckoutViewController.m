//
//  STPCheckoutViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 9/15/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import "STPCheckoutViewController.h"
#import "STPCheckoutOptions.h"
#import "STPToken.h"
#import "Stripe.h"

@interface STPCheckoutViewController()<UIWebViewDelegate>
@property(weak, nonatomic)UIWebView *webView;
@property(weak, nonatomic)UIActivityIndicatorView *activityIndicator;
@property(nonatomic)STPCheckoutOptions *options;
@end

@implementation STPCheckoutViewController

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _options = options;
        NSString *userAgent = [[UIWebView new] stringByEvaluatingJavaScriptFromString:@"window.navigator.userAgent"];
        if ([userAgent rangeOfString:@"StripeCheckout"].location == NSNotFound) {
            userAgent = [userAgent stringByAppendingString:@" StripeCheckout"];
            NSDictionary *defaults = @{@"UserAgent": userAgent};
            [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        }
    }
    return self;
}

- (NSString *)initialJavascript {
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"checkoutBridge" withExtension:@"js"];
    NSString *fileContents = [NSString stringWithContentsOfURL:fileUrl encoding:NSUTF8StringEncoding error:nil];
    return [NSString stringWithFormat:fileContents, [self.options stringifiedJavaScriptRepresentation]];
}

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
    [webView loadRequest:[[self class] checkoutURLRequest]];
    webView.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.options.headerBackgroundColor) {
        webView.backgroundColor = self.options.headerBackgroundColor;
    }
    
    webView.delegate = self;
    self.webView = webView;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[self class] colorIsLight:self.options.headerBackgroundColor] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.activityIndicator.center = self.view.center;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [webView stringByEvaluatingJavaScriptFromString:[self initialJavascript]];
    [self.activityIndicator startAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if (navigationType == UIWebViewNavigationTypeLinkClicked && [url.host isEqualToString:@"stripe.com"]) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
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
            STPToken *token = [[STPToken alloc] initWithAttributeDictionary:argData[0][@"token"]];
            [self.delegate checkoutController:self didFinishWithToken:token];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if ([url.host isEqualToString:@"closed"]) {
            if ([self.delegate respondsToSelector:@selector(checkoutControllerDidCancel:)]) {
                [self.delegate checkoutControllerDidCancel:self];
            }
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        return NO;
    }
    return navigationType == UIWebViewNavigationTypeOther;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIView animateWithDuration:0.2 animations:^{
        self.activityIndicator.alpha = 0;
    } completion:^(BOOL finished) {
        [self.activityIndicator stopAnimating];
    }];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    if ([self.delegate respondsToSelector:@selector(checkoutController:didFailWithError:)]) {
        [self.delegate checkoutController:self didFailWithError:error];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

+ (BOOL)colorIsLight:(UIColor *)color {
    const CGFloat *componentColors = CGColorGetComponents(color.CGColor);
    CGFloat colorBrightness = ((componentColors[0] * 299) + (componentColors[1] * 587) + (componentColors[2] * 114)) / 1000;
    return colorBrightness < 0.5;
}

+ (NSURLRequest *)checkoutURLRequest {
    NSString *url = @"https://checkout.stripe.com/v3";
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSMutableDictionary *userAgentDetails = [[Stripe stripeUserAgentDetails] mutableCopy];
    [userAgentDetails setValue:@"checkout-ios" forKey:@"source"];
    NSData *json = [NSJSONSerialization dataWithJSONObject:userAgentDetails
                                                   options:0
                                                     error:nil];
    NSString *userAgent = [[NSString alloc] initWithData:json
                                                encoding:NSUTF8StringEncoding];
    [urlRequest setValue:userAgent forHTTPHeaderField:STPUserAgentFieldName];
    return [urlRequest copy];
}

@end
