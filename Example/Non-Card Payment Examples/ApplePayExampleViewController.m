//
//  ApplePayExampleViewController.m
//  Non-Card Payment Examples
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

@import Stripe;
@import PassKit;

#import "ApplePayExampleViewController.h"
#import "BrowseExamplesViewController.h"
#import "Constants.h"
#import "ShippingManager.h"
#import "MyAPIClient.h"

/**
 This example demonstrates creating a payment using Apple Pay. First, we configure a PKPaymentRequest 
 with our payment information and use it to present the Apple Pay UI. When the user updates their
 shipping address, we use the example ShippingManager class to fetch the appropriate shipping methods for
 that address. After the user submits their information, the Stripe SDK completes the payment.
 */
@interface ApplePayExampleViewController () <STPApplePayContextDelegate>
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic, weak) PKPaymentButton *payButton;
@property (nonatomic, weak) UIActivityIndicatorView *activityIndicator;
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

    PKPaymentButton *button = [PKPaymentButton buttonWithType:PKPaymentButtonTypeBuy style:PKPaymentButtonStyleBlack];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;
    [self.view addSubview:button];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.hidesWhenStopped = YES;
    self.activityIndicator = activityIndicator;
    [self.view addSubview:activityIndicator];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    self.payButton.center = CGPointMake(CGRectGetMidX(bounds), 100);
    self.activityIndicator.center = CGPointMake(CGRectGetMidX(bounds),
                                                CGRectGetMaxY(self.payButton.frame) + 15*2);
}

- (NSArray *)_summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shirtItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Cool Shirt" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    NSDecimalNumber *total = [shirtItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Stripe Shirt Shop" amount:total];
    return @[shirtItem, shippingMethod, totalItem];
}

- (void)pay {
    // Build the payment request
    PKPaymentRequest *paymentRequest = [StripeAPI paymentRequestWithMerchantIdentifier:AppleMerchantId country:@"US" currency:@"USD"];
    [paymentRequest setRequiredShippingContactFields:[NSSet setWithObject:PKContactFieldPostalAddress]];
    [paymentRequest setRequiredBillingContactFields:[NSSet setWithObject:PKContactFieldPostalAddress]];
    paymentRequest.shippingMethods = [self.shippingManager defaultShippingMethods];
    paymentRequest.paymentSummaryItems = [self _summaryItemsForShippingMethod:paymentRequest.shippingMethods.firstObject];
    
    // Initialize STPApplePayContext
    STPApplePayContext *applePayContext = [[STPApplePayContext alloc] initWithPaymentRequest:paymentRequest delegate:self];

    // Present Apple Pay
    if (applePayContext) {
        [self.activityIndicator startAnimating];
        self.payButton.enabled = NO;
        [applePayContext presentApplePayOnViewController:self completion:nil];
    } else {
        NSLog(@"Make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/apple-pay#native");
    }
}

#pragma mark - STPApplePayContextDelegate

- (void)applePayContext:(STPApplePayContext *)context didCreatePaymentMethod:(STPPaymentMethod *)paymentMethod paymentInformation:(PKPayment *)paymentInformation completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // Create the Stripe PaymentIntent representing the payment on our backend
    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        // Call the completion block with the PaymentIntent's client secret
        completion(clientSecret, error);
    } additionalParameters:nil];
}

- (void)applePayContext:(STPApplePayContext *)context didCompleteWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    [self.activityIndicator stopAnimating];
    self.payButton.enabled = YES;

    switch (status) {
        case STPPaymentStatusSuccess:
            [self.delegate exampleViewController:self didFinishWithMessage:@"Payment successfully created"];
            break;
            
        case STPPaymentStatusError:
            [self.delegate exampleViewController:self didFinishWithError:error];
            break;
            
        case STPPaymentStatusUserCancellation:
            break;
    }
}

- (void)applePayContext:(STPApplePayContext *)context didSelectShippingContact:(PKContact *)contact handler:(void (^)(PKPaymentRequestShippingContactUpdate * _Nonnull))completion {
    [self.shippingManager fetchShippingCostsForAddress:contact.postalAddress
                                            completion:^(NSArray *shippingMethods, NSError *error) {
        completion([[PKPaymentRequestShippingContactUpdate alloc] initWithErrors:error ? @[error] : nil
                                                             paymentSummaryItems:[self _summaryItemsForShippingMethod:shippingMethods.firstObject]
                                                                 shippingMethods:shippingMethods]);
    }];
}

- (void)applePayContext:(STPApplePayContext *)context didSelectShippingMethod:(PKShippingMethod *)shippingMethod handler:(void (^)(PKPaymentRequestShippingMethodUpdate * _Nonnull))completion {
    NSArray *updatedSummaryItems = [self _summaryItemsForShippingMethod:shippingMethod];
    completion([[PKPaymentRequestShippingMethodUpdate alloc] initWithPaymentSummaryItems:updatedSummaryItems]);
}

@end
