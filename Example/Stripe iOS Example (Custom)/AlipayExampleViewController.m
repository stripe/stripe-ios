//
//  AlipayExampleViewController.m
//  Stripe iOS Example (Custom)
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "AlipayExampleViewController.h"
#import "BrowseExamplesViewController.h"

@interface AlipayExampleViewController ()
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPSource *source;
@end

@implementation AlipayExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Alipay";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with Alipay" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];

    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
    label.alpha = 0;
    [self.view addSubview:label];
    self.waitingLabel = label;

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.payButton.frame) + padding*2);
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress {
    self.navigationController.navigationBar.userInteractionEnabled = !paymentInProgress;
    self.payButton.enabled = !paymentInProgress;
    [UIView animateWithDuration:0.2 animations:^{
        self.waitingLabel.alpha = paymentInProgress ? 1 : 0;
    }];
    if (paymentInProgress) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (!request) return request;

    NSURL *url = request.URL;
    if ([url.host containsString:@"alipay.com"] ||
         ([url.host isEqualToString:@"stripe.com"] && [url.path isEqualToString:@"/sources/test_redirect"])) {
        [[UIApplication sharedApplication] openURL:url];
        return nil;
    }

    return request;
}

- (void)completeRedirect {
    [self updateUIForPaymentInProgress:NO];

    switch (self.source.status) {
        case STPSourceStatusChargeable:
        case STPSourceStatusConsumed:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            break;
        case STPSourceStatusCanceled:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Payment failed"];
            break;
        case STPSourceStatusPending:
        case STPSourceStatusFailed:
        case STPSourceStatusUnknown:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Order received"];
            break;
    }

}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)pay {
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    [self updateUIForPaymentInProgress:YES];
    STPSourceParams *sourceParams = [STPSourceParams new];
    sourceParams.rawTypeString = @"alipay";
    sourceParams.redirect = @{
                              @"return_url": @"payments-example://stripe-redirect"
                              };
    sourceParams.currency = @"jpy";
    sourceParams.amount = @(1099);
    [[STPAPIClient sharedClient] createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            // In order to use STPRedirectContext, you'll need to set up
            // your app delegate to forward URLs to the Stripe SDK.
            // See `[Stripe handleStripeURLCallback:]`
            self.source = source;
            NSURLRequest *request = [NSURLRequest requestWithURL:source.redirect.url];
            [NSURLConnection connectionWithRequest:request delegate:self];
        }
    }];
}
#pragma clang diagnostic pop

@end
