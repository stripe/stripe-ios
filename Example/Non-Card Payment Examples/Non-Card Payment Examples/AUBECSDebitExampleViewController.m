//
//  AUBECSDebitExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Cameron Sabol on 3/16/20.
//  Copyright © 2020 Stripe. All rights reserved.
//

@import Stripe;
@import StripePaymentsUI;

#import "AUBECSDebitExampleViewController.h"

#import "MyAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface AUBECSDebitExampleViewController () <STPAUBECSDebitFormViewDelegate> {
    STPAUBECSDebitFormView *_formView;
}

@end

@implementation AUBECSDebitExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"BECS Debit";

    [self.payButton setTitle:@"Pay with BECS Debit" forState:UIControlStateNormal];
    [self.payButton sizeToFit];
    self.payButton.enabled = NO;

    STPAUBECSDebitFormView *formView = [[STPAUBECSDebitFormView alloc] initWithCompanyName:@"Great Company Inc."];
    formView.becsDebitFormDelegate = self;
    formView.translatesAutoresizingMaskIntoConstraints = NO;
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor secondarySystemBackgroundColor];
    } else
#endif
    {
        // Fallback on earlier versions
        self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    }

    [self.view addSubview:formView];

    [NSLayoutConstraint activateConstraints:@[
        [formView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12.f],
        [formView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.view.trailingAnchor constraintEqualToAnchor:formView.trailingAnchor],
    ]];

    _formView = formView;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(_formView.frame) + 24.f);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.payButton.frame) + padding*2);
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)payButtonSelected {
    [self updateUIForPaymentInProgress:YES];

    STPPaymentMethodParams *params = _formView.paymentMethodParams;
    // Add any metadata
    params.metadata = @{@"sample_key": @"sample_value"};

    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        if (status == MyAPIClientResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];

        paymentIntentParams.paymentMethodParams = params;

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
    } additionalParameters:@"country=au"];

}

#pragma mark - STPAUBECSDebitFormViewDelegate

- (void)auBECSDebitForm:(STPAUBECSDebitFormView *)form didChangeToStateComplete:(BOOL)complete {
    self.payButton.enabled = complete;
}


@end

NS_ASSUME_NONNULL_END
