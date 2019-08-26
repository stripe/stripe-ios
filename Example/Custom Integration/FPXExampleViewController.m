//
//  FPXExampleViewController.m
//  Custom Integration
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "FPXExampleViewController.h"
#import "BrowseExamplesViewController.h"

/**
 This example demonstrates using PaymentMethods to accept payments using FPX, a popular payment method in Malaysia.
 First, we create an FPX PaymentMethodParams object with our payment details, and we send that to our server. The
 server returns a PaymentIntent with a URL, which we use to display an authorization page to the user. Once the
 user has gone through the authorization process, we query the Stripe API for the status of the PaymentIntent.
 */
@interface FPXExampleViewController ()
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, weak) UILabel *waitingLabel;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
@end

@implementation FPXExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
#endif
    self.title = @"FPX";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with AmBank (FPX)" forState:UIControlStateNormal];
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
    STPPaymentMethodFPXParams *fpx = [[STPPaymentMethodFPXParams alloc] init];
    fpx.bank = STPBankBrandAmbank;
    STPPaymentMethodParams *paymentMethodParams = [STPPaymentMethodParams paramsWithFPX:fpx billingDetails:nil metadata:nil];
    STPPaymentHandlerActionPaymentIntentCompletionBlock paymentHandlerCompletion = ^(STPPaymentHandlerActionStatus handlerStatus, STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable handlerError) {
        switch (handlerStatus) {
            case STPPaymentHandlerActionStatusFailed:
                [self.delegate exampleViewController:self didFinishWithError:handlerError];
                break;
            case STPPaymentHandlerActionStatusCanceled:
                [self.delegate exampleViewController:self didFinishWithMessage:@"Canceled authentication"];
                break;
            case STPPaymentHandlerActionStatusSucceeded:
                if (paymentIntent.status == STPPaymentIntentStatusRequiresConfirmation) {
                    // Manually confirm the PaymentIntent on the backend again to complete the payment.
                    [self.delegate confirmPaymentIntent:paymentIntent completion:^(STPBackendResult status, NSString *clientSecret, NSError *error) {
                        if (status == STPBackendResultFailure || error) {
                            [self.delegate exampleViewController:self didFinishWithError:error];
                            return;
                        }
                        [[STPAPIClient sharedClient] retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent *finalPaymentIntent, NSError *finalError) {
                            if (finalError) {
                                [self.delegate exampleViewController:self didFinishWithError:error];
                                return;
                            }
                            if (finalPaymentIntent.status == STPPaymentIntentStatusSucceeded) {
                                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
                            } else {
                                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment failed"];
                            }
                        }];
                    }];
                    break;
                } else {
                    [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
                }
        }
    };

    STPPaymentIntentCreateAndConfirmHandler createAndConfirmCompletion = ^(STPBackendResult status, NSString *clientSecret, NSError *error) {
        if (status == STPBackendResultFailure || error) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }
        [[STPPaymentHandler sharedHandler] handleNextActionForPayment:clientSecret
                                            withAuthenticationContext:self.delegate
                                                            returnURL:@"payments-example://stripe-redirect"
                                                           completion:paymentHandlerCompletion];
    };

    
    [self.delegate createAndConfirmPaymentIntentWithAmount:@(234) paymentMethodParams:paymentMethodParams returnURL:@"payments-example://stripe-redirect" completion:createAndConfirmCompletion];

}
#pragma clang diagnostic pop

@end
