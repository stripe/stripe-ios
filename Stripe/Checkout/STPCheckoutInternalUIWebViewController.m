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
#import "STPAPIResponseDecodable.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPCheckoutInternalUIWebViewController ()
@property (nonatomic) BOOL statusBarHidden;
@property (weak, nonatomic, nullable) UIView *webView;
@property (nonatomic, nullable) STPIOSCheckoutWebViewAdapter *adapter;
@property (nonatomic, nonnull) NSURL *url;
@property (weak, nonatomic, nullable) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL backendChargeSuccessful;
@property (nonatomic, nullable) NSError *backendChargeError;
@end

@implementation STPCheckoutInternalUIWebViewController

- (instancetype)initWithCheckoutViewController:(STPCheckoutViewController *)checkoutViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        _options = checkoutViewController.options;
        _url = [NSURL URLWithString:checkoutURLString];
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
    self.adapter = [[STPIOSCheckoutWebViewAdapter alloc] init];
    self.adapter.delegate = self;
    UIWebView *webView = self.adapter.webView;
    webView.scrollView.delegate = self;
    [self.view addSubview:webView];

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

    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && self.options.logoColor &&
        ![STPColorUtils colorIsLight:self.options.logoColor]) {
        style = UIActivityIndicatorViewStyleWhiteLarge;
    }
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
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
            token = [STPToken decodedObjectFromAPIResponse:payload[@"token"]];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    NSDictionary *options = [self checkoutDisplayOptionsForScrollViewOffset:scrollView.contentOffset];
    BOOL statusBarHidden = [options[@"statusBarHidden"] boolValue];
    NSString *backgroundColorHex = options[@"backgroundColor"];
    UIColor *color = backgroundColorHex ? [STPColorUtils colorForHexCode:backgroundColorHex] : [UIColor whiteColor];
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        self.statusBarHidden = statusBarHidden;
        [UIView animateWithDuration:0.1 animations:^{ [self setNeedsStatusBarAppearanceUpdate]; }];
        [[UIApplication sharedApplication] setStatusBarHidden:[self prefersStatusBarHidden] withAnimation:UIStatusBarAnimationSlide];
    }
    self.webView.backgroundColor = color;
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarHidden;
}

- (NSDictionary *)checkoutDisplayOptionsForScrollViewOffset:(CGPoint)offset {
    NSString *javascript = [NSString stringWithFormat:@"try { window.StripeCheckoutDidScroll(%@, %@) } catch(e){ null };", @(offset.x), @(offset.y)];
    NSString *output = [self.adapter evaluateJavaScript:javascript];
    return [NSJSONSerialization JSONObjectWithData:[output dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil] ?: @{};
}

@end

#pragma clang diagnostic pop

#endif
