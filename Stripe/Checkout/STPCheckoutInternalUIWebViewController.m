//
//  STPCheckoutInternalUIWebViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/7/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import "STPAPIClient.h"
#import "STPCheckoutOptions.h"
#import "STPCheckoutWebViewAdapter.h"
#import "STPIOSCheckoutWebViewAdapter.h"
#import "STPCheckoutInternalUIWebViewController.h"
#import "STPCheckoutViewController.h"
#import "StripeError.h"
#import "STPToken.h"
#import "STPColorUtils.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@implementation STPCheckoutInternalUIWebViewController

- (instancetype)initWithCheckoutViewController:(STPCheckoutViewController *)checkoutViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelItem;
        _checkoutController = checkoutViewController;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"window.navigator.userAgent"];
            if ([userAgent rangeOfString:checkoutUserAgent].location == NSNotFound) {
                userAgent = [NSString stringWithFormat:@"%@ %@/%@", userAgent, checkoutUserAgent, STPSDKVersion];
                NSDictionary *defaults = @{ @"UserAgent": userAgent };
                [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
            }
        });
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.url = [NSURL URLWithString:checkoutURLString];

    if (self.options.logoImage && !self.options.logoURL) {
        NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
        BOOL success = [UIImagePNGRepresentation(self.options.logoImage) writeToURL:url options:0 error:nil];
        if (success) {
            self.logoURL = self.options.logoURL = url;
        }
    }

    self.adapter = [[STPIOSCheckoutWebViewAdapter alloc] init];
    self.adapter.delegate = self;
    UIView *webView = self.adapter.webView;
    [self.view addSubview:webView];

    webView.backgroundColor = [UIColor whiteColor];
    if (self.options.logoColor && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.view.backgroundColor = self.options.logoColor;
        webView.backgroundColor = self.options.logoColor;
        webView.opaque = NO;
    }

    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];

    [self.adapter loadRequest:[NSURLRequest requestWithURL:self.url]];
    self.webView = webView;

    UIView *headerBackground = [[UIView alloc] initWithFrame:self.view.bounds];
    self.headerBackground = headerBackground;
    [self.webView insertSubview:headerBackground atIndex:0];
    headerBackground.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[headerBackground]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(headerBackground)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerBackground
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1
                                                           constant:0]];
    CGFloat bottomMargin = -150;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        bottomMargin = 0;
    }
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:headerBackground
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1
                                                           constant:bottomMargin]];

    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && self.options.logoColor &&
        ![STPColorUtils colorIsLight:self.options.logoColor]) {
        style = UIActivityIndicatorViewStyleWhiteLarge;
    }
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:activityIndicator];
    self.activityIndicator = activityIndicator;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1
                                                           constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicator
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1
                                                           constant:0]];
}

- (void)cancel:(__unused id)sender {
    [self.delegate checkoutController:self.checkoutController didFinishWithStatus:STPPaymentStatusUserCancelled error:nil];
    [self cleanup];
}

- (void)cleanup {
    [self.adapter cleanup];
    if (self.logoURL) {
        [[NSFileManager defaultManager] removeItemAtURL:self.logoURL error:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.options.logoColor && self.checkoutController.navigationBarHidden) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        return [STPColorUtils colorIsLight:self.options.logoColor] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

- (void)setLogoColor:(STP_COLOR_CLASS *)color {
    self.options.logoColor = color;
    self.headerBackground.backgroundColor = color;
    if ([self.checkoutController respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:YES];
        [self.checkoutController setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark STPCheckoutAdapterDelegate

- (void)checkoutAdapterDidStartLoad:(id<STPCheckoutWebViewAdapter>)adapter {
    NSString *optionsJavaScript = [NSString stringWithFormat:@"window.%@ = %@;", checkoutOptionsGlobal, [self.options stringifiedJSONRepresentation]];
    [adapter evaluateJavaScript:optionsJavaScript];
    [self.activityIndicator startAnimating];
}

- (void)checkoutAdapter:(id<STPCheckoutWebViewAdapter>)adapter didTriggerEvent:(NSString *)event withPayload:(NSDictionary *)payload {
    if ([event isEqualToString:STPCheckoutEventOpen]) {
        if (payload != nil && payload[@"logoColor"]) {
            [self setLogoColor:[STPColorUtils colorForHexCode:payload[@"logoColor"]]];
        }
    } else if ([event isEqualToString:STPCheckoutEventTokenize]) {
        STPToken *token = nil;
        if (payload != nil && payload[@"token"] != nil) {
            token = [[STPToken alloc] initWithAttributeDictionary:payload[@"token"]];
        }
        [self.delegate checkoutController:self.checkoutController
                           didCreateToken:token
                               completion:^(STPBackendChargeResult status, NSError *error) {
                                   self.backendChargeSuccessful = (status == STPBackendChargeResultSuccess);
                                   self.backendChargeError = error;
                                   if (status == STPBackendChargeResultSuccess) {
                                       [adapter evaluateJavaScript:payload[@"success"]];
                                   } else {
                                       NSString *failure = payload[@"failure"];
                                       NSString *encodedError = @"";
                                       if (error.localizedDescription) {
                                           encodedError = [[NSString alloc]
                                               initWithData:[NSJSONSerialization dataWithJSONObject:@[error.localizedDescription] options:0 error:nil]
                                                   encoding:NSUTF8StringEncoding];
                                           encodedError = [encodedError substringWithRange:NSMakeRange(2, encodedError.length - 4)];
                                       }
                                       NSString *script = [NSString stringWithFormat:failure, encodedError];
                                       [adapter evaluateJavaScript:script];
                                   }
                               }];
    } else if ([event isEqualToString:STPCheckoutEventFinish]) {
        if (self.backendChargeSuccessful) {
            [self.delegate checkoutController:self.checkoutController didFinishWithStatus:STPPaymentStatusSuccess error:nil];
        } else {
            [self.delegate checkoutController:self.checkoutController didFinishWithStatus:STPPaymentStatusError error:self.backendChargeError];
        }
        [self cleanup];
    } else if ([event isEqualToString:STPCheckoutEventCancel]) {
        [self.delegate checkoutController:self.checkoutController didFinishWithStatus:STPPaymentStatusUserCancelled error:nil];
        [self cleanup];
    } else if ([event isEqualToString:STPCheckoutEventError]) {
        NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
        [self.delegate checkoutController:self.checkoutController didFinishWithStatus:STPPaymentStatusError error:error];
        [self cleanup];
    }
}

- (void)checkoutAdapterDidFinishLoad:(__unused id<STPCheckoutWebViewAdapter>)adapter {
    [UIView animateWithDuration:0.1
        animations:^{
            self.activityIndicator.alpha = 0;
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
        completion:^(__unused BOOL finished) { [self.activityIndicator stopAnimating]; }];
}

- (void)checkoutAdapter:(__unused id<STPCheckoutWebViewAdapter>)adapter didError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    [self.delegate checkoutController:self.checkoutController didFinishWithStatus:STPPaymentStatusError error:error];
    [self cleanup];
}

@end

#endif
