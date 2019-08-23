//
//  ApplePayExampleViewController.m
//  Custom Integration
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <Stripe/Stripe.h>
#import "ApplePayExampleViewController.h"
#import "BrowseExamplesViewController.h"
#import "Constants.h"
#import "ShippingManager.h"

/**
 This example demonstrates creating a payment using Apple Pay. First, we configure a PKPaymentRequest 
 with our payment information and use it to present the Apple Pay UI. When the user updates their
 shipping address, we use the example ShippingManager class to fetch the appropriate shipping methods for
 that address. After the user submits their information, we create a token using the authorized PKPayment,
 and then send it to our backend to create the charge request.
 */
@interface ApplePayExampleViewController () <PKPaymentAuthorizationViewControllerDelegate, STPAuthenticationContext>
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic) BOOL applePaySucceeded;
@property (nonatomic) NSError *applePayError;
@property (nonatomic) PKPaymentAuthorizationViewController *applePayVC;
@end

@implementation ApplePayExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    #ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    }
    #endif
    self.title = @"Apple Pay";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    self.shippingManager = [[ShippingManager alloc] init];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Pay with Apple Pay" forState:UIControlStateNormal];
    [button sizeToFit];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    button.enabled = [self applePayEnabled];
    self.payButton = button;
    [self.view addSubview:button];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
}

- (BOOL)applePayEnabled {
    PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
    if (paymentRequest) {
        return [Stripe canSubmitPaymentRequest:paymentRequest];
    }
    return NO;
}

- (PKPaymentRequest *)buildPaymentRequest {
    if ([PKPaymentRequest class]) {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:AppleMerchantId
                                                                                country:@"US"
                                                                               currency:@"USD"];
        [paymentRequest setRequiredShippingAddressFields:PKAddressFieldPostalAddress];
        [paymentRequest setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
        paymentRequest.shippingMethods = [self.shippingManager defaultShippingMethods];
        paymentRequest.paymentSummaryItems = [self summaryItemsForShippingMethod:paymentRequest.shippingMethods.firstObject];
        return paymentRequest;
    }
    return nil;
}

- (void)pay {
    self.applePaySucceeded = NO;
    self.applePayError = nil;

    PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
        self.applePayVC = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        self.applePayVC.delegate = self;
        
        if (self.applePayVC) {
            [self presentViewController:self.applePayVC animated:YES completion:nil];
        } else {
            NSLog(@"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/mobile/apple-pay");
        }
    }
}

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shirtItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Cool Shirt" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    NSDecimalNumber *total = [shirtItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Stripe Shirt Shop" amount:total];
    return @[shirtItem, shippingMethod, totalItem];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(nonnull PKContact *)contact completion:(nonnull void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    [self.shippingManager fetchShippingCostsForAddress:contact.postalAddress
                                            completion:^(NSArray *shippingMethods, NSError *error) {
                                                if (error) {
                                                    completion(PKPaymentAuthorizationStatusFailure, @[], @[]);
                                                    return;
                                                }
                                                completion(PKPaymentAuthorizationStatusSuccess,
                                                           shippingMethods,
                                                           [self summaryItemsForShippingMethod:shippingMethods.firstObject]);
                                            }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
    completion(PKPaymentAuthorizationStatusSuccess, [self summaryItemsForShippingMethod:shippingMethod]);
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [[STPAPIClient sharedClient] createPaymentMethodWithPayment:payment completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
        if (error) {
            self.applePayError = error;
            completion(PKPaymentAuthorizationStatusFailure);
        } else {
            // We could also send the token.stripeID to our backend to create
            // a payment method and subsequent payment intent
            [self _createAndConfirmPaymentIntentWithPaymentMethod:paymentMethod
                                                       completion:completion];
        }
    }];
}

- (void)_createAndConfirmPaymentIntentWithPaymentMethod:(STPPaymentMethod *)paymentMethod completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    void (^finishWithStatus)(PKPaymentAuthorizationStatus) = ^(PKPaymentAuthorizationStatus status) {
        if (self.applePayVC) {
            completion(status);
        } else {
            [self _finish];
        }
    };
    void (^reconfirmPaymentIntent)(STPPaymentIntent *) = ^(STPPaymentIntent *paymentIntent) {
        [self.delegate confirmPaymentIntent:paymentIntent completion:^(STPBackendResult status, NSString *clientSecret, NSError *error) {
            if (status == STPBackendResultFailure || error) {
                self.applePayError = error;
                finishWithStatus(PKPaymentAuthorizationStatusFailure);
                return;
            }
            [[STPAPIClient sharedClient] retrievePaymentIntentWithClientSecret:clientSecret completion:^(STPPaymentIntent *finalPaymentIntent, NSError *finalError) {
                if (finalError) {
                    self.applePayError = finalError;
                    finishWithStatus(PKPaymentAuthorizationStatusFailure);
                    return;
                }
                if (finalPaymentIntent.status == STPPaymentIntentStatusSucceeded || finalPaymentIntent.status == STPPaymentIntentStatusRequiresCapture) {
                    self.applePaySucceeded = YES;
                    finishWithStatus(PKPaymentAuthorizationStatusSuccess);
                } else {
                    finishWithStatus(PKPaymentAuthorizationStatusFailure);
                }
            }];
        }];
    };
    STPPaymentHandlerActionPaymentIntentCompletionBlock paymentHandlerCompletion = ^(STPPaymentHandlerActionStatus handlerStatus, STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable handlerError) {
        switch (handlerStatus) {
            case STPPaymentHandlerActionStatusFailed:
                self.applePayError = handlerError;
                finishWithStatus(PKPaymentAuthorizationStatusFailure);
                break;
            case STPPaymentHandlerActionStatusCanceled:
                self.applePayError = [NSError errorWithDomain:StripeDomain code:123 userInfo:@{NSLocalizedDescriptionKey: @"User cancelled"}];
                finishWithStatus(PKPaymentAuthorizationStatusFailure);
                break;
            case STPPaymentHandlerActionStatusSucceeded:
                if (paymentIntent.status == STPPaymentIntentStatusRequiresConfirmation) {
                    // Manually confirm the PaymentIntent on the backend again to complete the payment.
                    reconfirmPaymentIntent(paymentIntent);
                    break;
                } else {
                    finishWithStatus(PKPaymentAuthorizationStatusSuccess);
                }
        }
    };
    STPPaymentIntentCreateAndConfirmHandler createAndConfirmCompletion = ^(STPBackendResult status, NSString *clientSecret, NSError *error) {
        if (status == STPBackendResultFailure || error) {
            self.applePayError = error;
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        [[STPPaymentHandler sharedHandler] handleNextActionForPayment:clientSecret
                                            withAuthenticationContext:self
                                                            returnURL:@"payments-example://stripe-redirect"
                                                           completion:paymentHandlerCompletion];
    };

    [self.delegate createAndConfirmPaymentIntentWithAmount:@(1000)
                                             paymentMethod:paymentMethod.stripeId
                                                 returnURL:@"payments-example://stripe-redirect"
                                                completion:createAndConfirmCompletion];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        // This only gets called if you call the PKPaymentAuthorizationStatus completion block before dismissing PKPaymentAuthorizationViewController
        [self dismissViewControllerAnimated:YES completion:^{
            [self _finish];
        }];
    });
}

- (void)_finish {
    if (self.applePaySucceeded) {
        [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
    } else if (self.applePayError) {
        [self.delegate exampleViewController:self didFinishWithError:self.applePayError];
    }
    self.applePaySucceeded = NO;
    self.applePayError = nil;
    self.applePayVC = nil;
}

#pragma mark - STPAuthenticationContext

- (UIViewController *)authenticationPresentingViewController {
    return self;
}

- (void)prepareAuthenticationContextForPresentation:(STPVoidBlock)completion {
    if (self.applePayVC.presentingViewController != nil) {
        [self dismissViewControllerAnimated:YES completion:^{
            self.applePayVC = nil;
            completion();
        }];
    } else {
        completion();
    }
}

@end
