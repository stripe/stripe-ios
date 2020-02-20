//
//  ApplePayExampleViewController.m
//  Non-Card Payment Examples
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
 that address. After the user submits their information, the Stripe SDK completes the payment.
 */
@interface ApplePayExampleViewController () <STPApplePayDelegate>
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic, weak) PKPaymentButton *payButton;
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

    PKPaymentButton *button = [PKPaymentButton buttonWithType:PKPaymentButtonTypeBuy style:PKPaymentButtonStyleBlack];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
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
    PKPaymentRequest *paymentRequest = [self buildPaymentRequest];
    self.applePayVC = [Stripe applePayViewControllerWithPaymentRequest:paymentRequest
                                                             apiClient:[STPAPIClient sharedClient]
                                                              delegate:self
                                                            completion:^(STPPaymentStatus status, NSError * _Nullable error) {
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
    }];
    
    if (self.applePayVC) {
        [self presentViewController:self.applePayVC animated:YES completion:nil];
    } else {
        NSLog(@"Apple Pay returned a nil PKPaymentAuthorizationViewController - make sure you've configured Apple Pay correctly, as outlined at https://stripe.com/docs/apple-pay#native");
    }
}

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shirtItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Cool Shirt" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    NSDecimalNumber *total = [shirtItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Stripe Shirt Shop" amount:total];
    return @[shirtItem, shippingMethod, totalItem];
}

#pragma mark - STPApplePayDelegate

- (void)createPaymentIntentWithPaymentMethod:(NSString *)paymentMethodID completion:(STPPaymentIntentClientSecretCompletionBlock)completion {
    [[MyAPIClient sharedClient] createPaymentIntentWithCompletion:^(MyAPIClientResult status, NSString *clientSecret, NSError *error) {
        completion(clientSecret, error);
    } additionalParameters:nil];
}

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

@end
