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
#import "STPColorUtils.h"
#import "STPCheckoutURLProtocol.h"
#import "FauxPasAnnotations.h"

@interface STPCheckoutViewController () <UIWebViewDelegate>
@property (weak, nonatomic) UIWebView *webView;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) UIStatusBarStyle previousStyle;
@property (nonatomic) STPCheckoutOptions *options;
@property (nonatomic) NSURL *logoURL;
@property (nonatomic) NSURL *url;
@property (nonatomic) UIToolbar *cancelToolbar;
@end

@implementation STPCheckoutViewController

static NSString *const checkoutOptionsGlobal = @"StripeCheckoutOptions";
static NSString *const checkoutRedirectPrefix = @"/-/";
static NSString *const checkoutRPCScheme = @"stripecheckout";
static NSString *const checkoutUserAgent = @"Stripe";
// static NSString *const checkoutURL = @"checkout.stripe.com/v3/ios";
static NSString *const checkoutURL = @"localhost:5394/v3/ios";

- (instancetype)initWithOptions:(STPCheckoutOptions *)options {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _options = options;
        _previousStyle = [[UIApplication sharedApplication] statusBarStyle];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *userAgent = [[[UIWebView alloc] init] stringByEvaluatingJavaScriptFromString:@"window.navigator.userAgent"];
            if ([userAgent rangeOfString:checkoutUserAgent].location == NSNotFound) {
                userAgent = [NSString stringWithFormat:@"%@ %@/%@", userAgent, checkoutUserAgent, STPLibraryVersionNumber];
                NSDictionary *defaults = @{ @"UserAgent": userAgent };
                [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
            }
            [NSURLProtocol registerClass:[STPCheckoutURLProtocol class]];
        });
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *fullURLString = [NSString stringWithFormat:@"%@://%@", STPCheckoutURLProtocolRequestScheme, checkoutURL];
    self.url = [NSURL URLWithString:fullURLString];

    if (self.options.logoImage && !self.options.logoURL) {
        NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]]];
        BOOL success = [UIImagePNGRepresentation(self.options.logoImage) writeToURL:url options:0 error:nil];
        if (success) {
            self.logoURL = self.options.logoURL = url;
        }
    }

    UIWebView *webView = [[UIWebView alloc] init];
    [self.view addSubview:webView];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(webView)]];
    webView.keyboardDisplayRequiresUserAction = NO;
    webView.backgroundColor = [UIColor whiteColor];
    self.view.backgroundColor = [UIColor whiteColor];
    if (self.options.logoColor) {
        webView.backgroundColor = self.options.logoColor;
    }
    [webView loadRequest:[NSURLRequest requestWithURL:self.url]];
    webView.delegate = self;
    self.webView = webView;

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
                                                           constant:-40.0]];

    // We're going to use a toolbar here instead of a UIButton so that we can get UIKit's localization of the word "Cancel" for free.
    UIToolbar *cancelToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44)];
    cancelToolbar.translatesAutoresizingMaskIntoConstraints = NO;
    cancelToolbar.translucent = NO;
    cancelToolbar.backgroundColor = [UIColor clearColor];
    cancelToolbar.clipsToBounds = YES;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    cancelToolbar.items = @[leftItem, cancelItem, rightItem];
    cancelToolbar.alpha = 0;
    cancelToolbar.hidden = YES;
    [self.view addSubview:cancelToolbar];
    self.cancelToolbar = cancelToolbar;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[cancelToolbar]-0-|"
                                                                      options:NSLayoutFormatDirectionLeadingToTrailing
                                                                      metrics:nil
                                                                        views:NSDictionaryOfVariableBindings(cancelToolbar)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:cancelToolbar
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:activityIndicator
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1
                                                           constant:10.0]];
}

- (void)cancel:(UIBarButtonItem *)sender {
    [self.delegate checkoutControllerDidCancel:self];
    [self cleanup];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.options.logoColor) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        return [STPColorUtils colorIsLight:self.options.logoColor] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    }
    return UIStatusBarStyleDefault;
}

- (void)cleanup {
    if ([self.webView isLoading]) {
        [self.webView stopLoading];
    }
    [[UIApplication sharedApplication] setStatusBarStyle:self.previousStyle animated:YES];
    if (self.logoURL) {
        [[NSFileManager defaultManager] removeItemAtURL:self.logoURL error:nil];
    }
}

- (void)setLogoColor:(UIColor *)color {
    self.options.logoColor = color;
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
        [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:YES];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSString *optionsJavaScript = [NSString stringWithFormat:@"window.%@ = %@;", checkoutOptionsGlobal, [self.options stringifiedJSONRepresentation]];
    [webView stringByEvaluatingJavaScriptFromString:optionsJavaScript];
    [self.activityIndicator startAnimating];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.cancelToolbar.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{ self.cancelToolbar.alpha = 1.0f; }];
    });
}

- (BOOL)webView:(__unused UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;
    if (navigationType == UIWebViewNavigationTypeLinkClicked && [url.host isEqualToString:self.url.host] &&
        [url.path rangeOfString:checkoutRedirectPrefix].location == 0) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    if ([url.scheme isEqualToString:checkoutRPCScheme]) {
        NSString *event = url.host;
        NSString *path = [url.path componentsSeparatedByString:@"/"][1];
        NSDictionary *payload = nil;
        if (path != nil) {
            payload = [NSJSONSerialization JSONObjectWithData:[path dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        }

        if ([event isEqualToString:@"CheckoutDidOpen"]) {
            if (payload != nil && payload[@"logoColor"]) {
                [self setLogoColor:[STPColorUtils colorForHexCode:payload[@"logoColor"]]];
            }
        } else if ([event isEqualToString:@"CheckoutDidTokenize"]) {
            STPToken *token = nil;
            if (payload != nil && payload[@"token"] != nil) {
                token = [[STPToken alloc] initWithAttributeDictionary:payload[@"token"]];
            }
            [self.delegate checkoutController:self
                               didCreateToken:token
                                   completion:^(STPBackendChargeResult status, NSError *error) {
                                       if (status == STPBackendChargeResultSuccess) {
                                           // @reggio: do something here like [self.webView
                                           // stringByEvaluatingStringFromJavascript:@"showCheckoutSuccessAnimation();"]
                                           // that should probably trigger the "CheckoutDidFinish" event when the animation is complete
                                       } else {
                                           // @reggio: do something here like [self.webView
                                           // stringByEvaluatingStringFromJavascript:@"showCheckoutFailureAnimation();"]
                                           // that should probably trigger the "CheckoutDidError" event when the animation is complete
                                       }
                                   }];
        } else if ([event isEqualToString:@"CheckoutDidFinish"]) {
            [self.delegate checkoutControllerDidFinish:self];
            [self cleanup];
        } else if ([url.host isEqualToString:@"CheckoutDidCancel"]) {
            [self.delegate checkoutControllerDidCancel:self];
            [self cleanup];
        } else if ([event isEqualToString:@"CheckoutDidError"]) {
            NSError *error = [[NSError alloc] initWithDomain:StripeDomain code:STPCheckoutError userInfo:payload];
            [self.delegate checkoutController:self didFailWithError:error];
            [self cleanup];
        }
        return NO;
    }
    return navigationType == UIWebViewNavigationTypeOther;
}

- (void)webViewDidFinishLoad:(__unused UIWebView *)webView {
    [UIView animateWithDuration:0.1
        animations:^{
            self.cancelToolbar.alpha = 0;
            self.activityIndicator.alpha = 0;
        }
        completion:^(BOOL finished) {
            self.cancelToolbar.hidden = YES;
            [self.activityIndicator stopAnimating];
        }];
}

- (void)webView:(__unused UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.activityIndicator stopAnimating];
    [self.delegate checkoutController:self didFailWithError:error];
    [self cleanup];
}

@end
