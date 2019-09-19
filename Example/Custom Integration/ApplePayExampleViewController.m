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
#import "MyAPIClient.h"

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
        [paymentRequest setRequiredShippingContactFields:[NSSet setWithObject:PKContactFieldPostalAddress]];
        [paymentRequest setRequiredBillingContactFields:[NSSet setWithObject:PKContactFieldPostalAddress]];
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

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(PKContact *)contact handler:(void (^)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion {
    [self.shippingManager fetchShippingCostsForAddress:contact.postalAddress
                                            completion:^(NSArray *shippingMethods, NSError *error) {
                                                completion([[PKPaymentRequestShippingContactUpdate alloc] initWithErrors:error ? @[error] : nil
                                                                                                     paymentSummaryItems:[self summaryItemsForShippingMethod:shippingMethods.firstObject]
                                                                                                         shippingMethods:shippingMethods]);
                                            }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod handler:(void (^)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion {
    completion([[PKPaymentRequestShippingMethodUpdate alloc] initWithPaymentSummaryItems:[self summaryItemsForShippingMethod:shippingMethod]]);
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion  API_AVAILABLE(ios(11.0)) {
    [[STPAPIClient sharedClient] createPaymentMethodWithPayment:payment completion:^(STPPaymentMethod *paymentMethod, NSError *error) {
        if (error) {
            NSError *pkError = [STPAPIClient pkPaymentErrorForStripeError:error];
            PKPaymentAuthorizationResult *result = [[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:@[pkError]];
            completion(result);
        } else {
            // We could also send the token.stripeID to our backend to create
            // a payment method and subsequent payment intent
            [self _createAndConfirmPaymentIntentWithPaymentMethod:paymentMethod
                                                       completion:completion];
        }
    }];
}

- (void)_createAndConfirmPaymentIntentWithPaymentMethod:(STPPaymentMethod *)paymentMethod completion:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion {
    // Some observations on iOS 12 simulator:
    // - If you call the completion block w/ a status of .failure and an error, the user is prompted to try again. Otherwise, the sheet is dismissed.
    // - The docs say localizedDescription can be shown in the Apple Pay sheet, but I haven't observed this.
    
    // 3. Check the status
    STPPaymentHandlerActionPaymentIntentCompletionBlock paymentHandlerCompletion = ^(STPPaymentHandlerActionStatus handlerStatus, STPPaymentIntent * _Nullable paymentIntent, NSError * _Nullable handlerError) {
        switch (handlerStatus) {
            case STPPaymentHandlerActionStatusFailed:
                self.applePayError = handlerError;
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure
                                                                         errors:@[[STPAPIClient pkPaymentErrorForStripeError:self.applePayError]]]);
                break;
            case STPPaymentHandlerActionStatusCanceled:
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
                break;
            case STPPaymentHandlerActionStatusSucceeded:
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
                break;
        }
    };
    
    // 1. Create a PaymentIntent on the backend. This is typically done at the beginning of the checkout flow.
    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        if (status == MyAPIClientResultFailure || error) {
            self.applePayError = error;
            completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure
                                                                     errors:@[[STPAPIClient pkPaymentErrorForStripeError:self.applePayError]]]);
            return;
        }

        STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:clientSecret];
        paymentIntentParams.paymentMethodId = paymentMethod.stripeId;
        
        // 2. Confirm the PaymentIntent with the Apple Pay PaymentMethod
        [[STPPaymentHandler sharedHandler] confirmPayment:paymentIntentParams
                                withAuthenticationContext:self
                                               completion:paymentHandlerCompletion];
    }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        // This only gets called if you call the PKPaymentAuthorizationStatus completion block before dismissing PKPaymentAuthorizationViewController
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.applePaySucceeded) {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            } else if (self.applePayError) {
                [self.delegate exampleViewController:self didFinishWithError:self.applePayError];
            }
            self.applePaySucceeded = NO;
            self.applePayError = nil;
            self.applePayVC = nil;
        }];
    });
}

#pragma mark - STPAuthenticationContext

- (UIViewController *)authenticationPresentingViewController {
    return self;
}

@end
