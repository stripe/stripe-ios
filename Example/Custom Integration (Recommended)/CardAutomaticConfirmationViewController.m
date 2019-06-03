//
//  CardAutomaticConfirmationViewController.m
//  Custom Integration (Recommended)
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

@import Stripe;

#import "CardAutomaticConfirmationViewController.h"
#import "BrowseExamplesViewController.h"

/**
 This example demonstrates using PaymentIntents to accept card payments verified using 3D Secure.

 1. Collect user's card information via `STPPaymentCardTextField`
 2. Create a `PaymentIntent` on our backend (this can happen concurrently with #1)
 3. Confirm PaymentIntent using the `STPPaymentMethodParams` for the user's card information.
 4. If the user needs to go through the 3D Secure authentication flow, use `STPRedirectContext` to do so.
 5. When user returns to the app, or finishes the SafariVC redirect flow, `STPRedirectContext` notifies via callback

 See the documentation at https://stripe.com/docs/payments/payment-intents/ios for more information
 on using PaymentIntents for dynamic authentication.
 */
@interface CardAutomaticConfirmationViewController () <STPPaymentCardTextFieldDelegate>

@property (weak, nonatomic) STPPaymentCardTextField *paymentTextField;
@property (weak, nonatomic) UILabel *waitingLabel;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation CardAutomaticConfirmationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Card";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    STPPaymentCardTextField *paymentTextField = [[STPPaymentCardTextField alloc] init];
    STPPaymentMethodCardParams *cardParams = [STPPaymentMethodCardParams new];
    // Only successful 3D Secure transactions on this test card will succeed.
    cardParams.number = @"4000000000003063";
    paymentTextField.cardParams = cardParams;
    paymentTextField.delegate = self;
    paymentTextField.cursorColor = [UIColor purpleColor];
    self.paymentTextField = paymentTextField;
    [self.view addSubview:paymentTextField];

    UILabel *label = [UILabel new];
    label.text = @"Waiting for payment authorization";
    [label sizeToFit];
    label.textColor = [UIColor grayColor];
    label.alpha = 0;
    [self.view addSubview:label];
    self.waitingLabel = label;

    NSString *title = @"Pay";
    UIBarButtonItem *payButton = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:self action:@selector(pay)];
    payButton.enabled = paymentTextField.isValid;
    self.navigationItem.rightBarButtonItem = payButton;

    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.paymentTextField becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat padding = 15;
    CGFloat width = CGRectGetWidth(self.view.frame) - (padding*2);
    CGRect bounds = self.view.bounds;
    self.paymentTextField.frame = CGRectMake(padding, padding, width, 44);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.paymentTextField.frame) + padding*2);
    self.waitingLabel.center = CGPointMake(CGRectGetMidX(bounds),
                                           CGRectGetMaxY(self.activityIndicator.frame) + padding*2);
}

- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress {
    self.navigationController.navigationBar.userInteractionEnabled = !paymentInProgress;
    self.navigationItem.rightBarButtonItem.enabled = !paymentInProgress;
    self.paymentTextField.userInteractionEnabled = !paymentInProgress;
    [UIView animateWithDuration:0.2 animations:^{
        self.waitingLabel.alpha = paymentInProgress ? 1 : 0;
    }];
    if (paymentInProgress) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
}

- (void)paymentCardTextFieldDidChange:(nonnull STPPaymentCardTextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = textField.isValid;
}

- (void)pay {
    if (![self.paymentTextField isValid]) {
        return;
    }
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    [self updateUIForPaymentInProgress:YES];

    // In a more interesting app, you'll probably create your PaymentIntent as soon as you know the
    // payment amount you wish to collect from your customer. For simplicity, this example does it once they've
    // pushed the Pay button.
    // https://stripe.com/docs/payments/dynamic-authentication#create-payment-intent
    [self.delegate createBackendPaymentIntentWithAmount:@1099 completion:^(STPBackendResult status, NSString *clientSecret, NSError *error) {
        if (status == STPBackendResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPAPIClient *stripeClient = [STPAPIClient sharedClient];
        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
        paymentIntentParams.paymentMethodParams = [STPPaymentMethodParams paramsWithCard:self.paymentTextField.cardParams
                                                                          billingDetails:nil
                                                                                metadata:nil];
        paymentIntentParams.returnURL = @"payments-example://stripe-redirect";

        [stripeClient confirmPaymentIntentWithParams:paymentIntentParams completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
            if (error) {
                [self.delegate exampleViewController:self didFinishWithError:error];
                return;
            }

            if (paymentIntent.status == STPPaymentIntentStatusRequiresAction) {
                [self.delegate performRedirectForViewController:self
                                              withPaymentIntent:paymentIntent
                                                     completion:^(STPPaymentIntent *retrievedIntent, NSError *error) {
                                                         if (error) {
                                                             [self.delegate exampleViewController:self didFinishWithError:error];
                                                         } else {
                                                             [self finishWithStatus:retrievedIntent.status];
                                                         }
                                                     }];
            } else {
                [self finishWithStatus:paymentIntent.status];
            }
        }];
    }];
}

- (void)finishWithStatus:(STPPaymentIntentStatus)status {
    switch (status) {
        // There may have been a problem with the payment method (STPPaymentMethodParams or STPSourceParams)
        case STPPaymentIntentStatusRequiresPaymentMethod:
        // did you call `confirmPaymentIntentWithParams:completion`?
        case STPPaymentIntentStatusRequiresConfirmation:
        // App should have handled the action, but didn't for some reason
        case STPPaymentIntentStatusRequiresAction:
        // The PaymentIntent was canceled (maybe by the backend?)
        case STPPaymentIntentStatusCanceled:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Payment failed"];
            break;

        // Processing. You could detect this case and poll for the final status of the PaymentIntent
        case STPPaymentIntentStatusProcessing:
        // Unknown status
        case STPPaymentIntentStatusUnknown:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Order received"];
            break;

        // if captureMethod is manual, backend needs to capture it to receive the funds
        case STPPaymentIntentStatusRequiresCapture:
        // succeeded
        case STPPaymentIntentStatusSucceeded:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            break;
    }
}

@end
