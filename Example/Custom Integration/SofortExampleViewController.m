//
//  SofortExampleViewController.m
//  Custom Integration
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "SofortExampleViewController.h"
#import "BrowseExamplesViewController.h"

/**
 SOFORT is not currently supported by PaymentMethods, so integration requires the use of Sources.
 ref. https://stripe.com/docs/payments/payment-methods#transitioning

 This example demonstrates using Sources to accept payments using SOFORT, a popular payment method in Europe.
 First, we create a Sofort Source object with our payment details. We then redirect the user to the URL
 in the Source object to authorize the payment, and start polling the Source so that we can display the
 appropriate status when the user returns to the app. 

 Because Sofort payments require further action from the user, we don't tell our backend to create a charge
 request in this example. Instead, your backend should listen to the `source.chargeable` webhook event to 
 charge the source. See https://stripe.com/docs/sources#best-practices for more information.
 */
@interface SofortExampleViewController ()
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) STPRedirectContext *redirectContext;
@end

@implementation SofortExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
    #endif
    self.title = @"Sofort";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with Sofort" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];

    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        label.textColor = [UIColor secondaryLabelColor];
    }
    #endif
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)pay {
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    [self updateUIForPaymentInProgress:YES];
    STPSourceParams *sourceParams = [STPSourceParams sofortParamsWithAmount:1099
                                                                  returnURL:@"payments-example://stripe-redirect"
                                                                    country:@"DE"
                                                        statementDescriptor:@"ORDER AT11990"];
    [[STPAPIClient sharedClient] createSourceWithParams:sourceParams completion:^(STPSource *source, NSError *error) {
        if (error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
        } else {
            // In order to use STPRedirectContext, you'll need to set up
            // your app delegate to forward URLs to the Stripe SDK.
            // See `[Stripe handleStripeURLCallback:]`
            self.redirectContext = [[STPRedirectContext alloc] initWithSource:source completion:^(NSString *sourceID, NSString *clientSecret, NSError *error) {
                if (error) {
                    [self.delegate exampleViewController:self didFinishWithError:error];
                } else {
                    [[STPAPIClient sharedClient] startPollingSourceWithId:sourceID
                                                             clientSecret:clientSecret
                                                                  timeout:10
                                                               completion:^(STPSource *source, NSError *error) {
                                                                   [self updateUIForPaymentInProgress:NO];
                                                                   if (error) {
                                                                       [self.delegate exampleViewController:self didFinishWithError:error];
                                                                   } else {
                                                                       switch (source.status) {
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
                                                                   self.redirectContext = nil;
                                                               }];
                }
            }];
            [self.redirectContext startRedirectFlowFromViewController:self];
        }
    }];
}
#pragma clang diagnostic pop

@end
