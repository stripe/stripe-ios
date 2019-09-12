//
//  FPXExampleViewController.m
//  Custom Integration
//
//  Created by David Estes on 8/26/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "FPXExampleViewController.h"
#import "BrowseExamplesViewController.h"
#import "ExampleAPIClient.h"

/**
 This example demonstrates using PaymentIntents to accept payments using FPX, a popular
 payment method in Malaysia.
 First, we ask our server to set up a PaymentIntent. We create a PaymentMethodParams with the
 details of our selected FPX-supporting bank, then call STPPaymentHandler to confirm the PaymentIntent
 using the Stripe API.
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

    [[ExampleAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        if (status == MyAPIClientResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
        STPPaymentMethodFPXParams *fpx = [[STPPaymentMethodFPXParams alloc] init];
        fpx.bank = STPFPXBankBrandAmbank;
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithFPX:fpx billingDetails:nil metadata:nil];
        paymentIntentParams.returnURL = @"payments-example://stripe-redirect";
        [[STPPaymentHandler sharedHandler] confirmPayment:paymentIntentParams
                                withAuthenticationContext:self.delegate
                                               completion:^(STPPaymentHandlerActionStatus handlerStatus, STPPaymentIntent * handledIntent, NSError * _Nullable handlerError) {
                                                   switch (handlerStatus) {
                                                       case STPPaymentHandlerActionStatusFailed:
                                                           [self.delegate exampleViewController:self didFinishWithError:handlerError];
                                                           break;
                                                       case STPPaymentHandlerActionStatusCanceled:
                                                           [self.delegate exampleViewController:self didFinishWithMessage:@"Canceled"];
                                                           break;
                                                       case STPPaymentHandlerActionStatusSucceeded:
                                                           [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
                                                           break;
                                                   }
                                               }];
    }];
}
#pragma clang diagnostic pop

@end
