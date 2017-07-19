//
//  ApplePayExampleViewController.m
//  Custom Integration (ObjC)
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
@interface ApplePayExampleViewController () <PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic) BOOL applePaySucceeded;
@property (nonatomic) NSError *applePayError;
@end

@implementation ApplePayExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Apple Pay";
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

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
        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        auth.delegate = self;
        if (auth) {
            [self presentViewController:auth animated:YES completion:nil];
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

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingAddress:(ABRecordRef)address completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> *, NSArray<PKPaymentSummaryItem *> *))completion {
    [self.shippingManager fetchShippingCostsForAddress:address
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
    [[STPAPIClient sharedClient] createTokenWithPayment:payment
                                             completion:^(STPToken *token, NSError *error) {
                                                 [self.delegate createBackendChargeWithSource:token.tokenId
                                                                                   completion:^(STPBackendChargeResult status, NSError *error) {
                                                                                       if (status == STPBackendChargeResultSuccess) {
                                                                                           self.applePaySucceeded = YES;
                                                                                           completion(PKPaymentAuthorizationStatusSuccess);
                                                                                       } else {
                                                                                           self.applePayError = error;
                                                                                           completion(PKPaymentAuthorizationStatusFailure);
                                                                                       }
                                                                                   }];
                                             }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.applePaySucceeded) {
                [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            } else if (self.applePayError) {
                [self.delegate exampleViewController:self didFinishWithError:self.applePayError];
            }
            self.applePaySucceeded = NO;
            self.applePayError = nil;
        }];
    });
}

@end
