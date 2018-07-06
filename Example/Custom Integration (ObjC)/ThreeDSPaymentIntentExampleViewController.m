//
//  ThreeDSPaymentIntentExampleViewController.m
//  Custom Integration (ObjC)
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

@import Stripe;

#import "ThreeDSPaymentIntentExampleViewController.h"
#import "BrowseExamplesViewController.h"

@interface ThreeDSExampleViewController (PrivateMethods)
- (void)updateUIForPaymentInProgress:(BOOL)paymentInProgress;

@property (weak, nonatomic) STPPaymentCardTextField *paymentTextField;
@property (nonatomic) STPRedirectContext *redirectContext;
@end

/**
 This example demonstrates using PaymentIntents to accept card payments verified using 3D Secure.
 This builds on ThreeDSExampleViewController, which has the same UI but creates a Source instead of using
 PaymentIntents.

 1. Collect user's card information via `STPPaymentCardTextField`
 2. Create a `PaymentIntent` on our backend (this can happen concurrently with #1)
 3. Confirm PaymentIntent using the `STPSourceParams` for the user's card information.
 4. If the user needs to go through the 3D Secure authentication flow, use `STPRedirectContext` to do so.
 5. When user returns to the app, or finishes the SafariVC redirect flow, `STPRedirectContext` notifies via callback

 See the documentation at https://stripe.com/docs/payments/dynamic-authentication for more information
 on using PaymentIntents for dynamic authentication.
 */
@interface ThreeDSPaymentIntentExampleViewController ()

@end

@implementation ThreeDSPaymentIntentExampleViewController

- (void)pay {
    if (![self.paymentTextField isValid]) {
        return;
    }
    if (![Stripe defaultPublishableKey]) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Please set a Stripe Publishable Key in Constants.m"];
        return;
    }
    [self updateUIForPaymentInProgress:YES];

    NSString *returnUrl = @"payments-example://stripe-redirect";
    // In a more interesting app, you'll probably create your PaymentIntent as soon as you know the
    // payment amount you wish to collect from your customer. For simplicity, this example does it once they've
    // pushed the Pay button.
    // https://stripe.com/docs/payments/dynamic-authentication#create-payment-intent
    [self.delegate createBackendPaymentIntentWithAmount:@1099 returnUrl:returnUrl completion:^(STPBackendResult status, NSString *clientSecret, NSError *error) {
        if (status == STPBackendResultFailure || clientSecret == nil) {
            [self.delegate exampleViewController:self didFinishWithError:error];
            return;
        }

        STPAPIClient *stripeClient = [STPAPIClient sharedClient];
        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
        paymentIntentParams.sourceParams = [STPSourceParams cardParamsWithCard:self.paymentTextField.cardParams];

        [stripeClient confirmPaymentIntentWithParams:paymentIntentParams completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
            if (error) {
                [self.delegate exampleViewController:self didFinishWithError:error];
                return;
            }

            if (paymentIntent.status == STPPaymentIntentStatusRequiresSourceAction) {
                self.redirectContext = [[STPRedirectContext alloc] initWithPaymentIntent:paymentIntent returnUrl:returnUrl completion:^(NSString * _Nonnull clientSecret, NSError * _Nullable error) {
                    if (error) {
                        [self.delegate exampleViewController:self didFinishWithError:error];
                    }
                    else {
                        [stripeClient retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable error) {
                            if (error) {
                                [self.delegate exampleViewController:self didFinishWithError:error];
                            } else {
                                [self finishWithStatus:paymentIntent.status];
                            }
                        }];
                    }
                    self.redirectContext = nil; // break retain cycle
                }];

                if (self.redirectContext) {
                    [self.redirectContext startRedirectFlowFromViewController:self];
                }
                else {
                    // Could not create STPRedirectContext even though it RequiresSourceAction
                    [self finishWithStatus:paymentIntent.status];
                }
            }
            else {
                [self finishWithStatus:paymentIntent.status];
            }
        }];
    }];
}

- (void)finishWithStatus:(STPPaymentIntentStatus)status {
    switch (status) {
        // There may have been a problem with the STPSourceParams
        case STPPaymentIntentStatusRequiresSource:
        // did you call `confirmPaymentIntentWithParams:completion`?
        case STPPaymentIntentStatusRequiresConfirmation:
        // App should have handled the source action, but didn't for some reason
        case STPPaymentIntentStatusRequiresSourceAction:
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
