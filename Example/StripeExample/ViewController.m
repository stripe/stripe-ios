//
//  ViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Parse/Parse.h>
#import "ViewController.h"
#import "Stripe.h"
#import "Constants.h"
#import "Stripe+ApplePay.h"
#import <AddressBook/AddressBook.h>
#import "PaymentViewController.h"

#if DEBUG
#import "STPTestPaymentAuthorizationViewController.h"
#import "PKPayment+STPTestKeys.h"
#endif

@interface ViewController()<PKPaymentAuthorizationViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *cartLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkoutButton;
@property (nonatomic) NSDecimalNumber *amount;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    [self updateCartWithNumberOfShirts:0];
}

- (void)updateCartWithNumberOfShirts:(NSUInteger)numberOfShirts {
    NSInteger price = 10;
    self.amount = [NSDecimalNumber decimalNumberWithMantissa:numberOfShirts*price exponent:0 isNegative:NO];
    self.cartLabel.text = [NSString stringWithFormat:@"%@ shirts = $%@", @(numberOfShirts), self.amount];
    self.checkoutButton.enabled = numberOfShirts > 0;
}

- (IBAction)changeCart:(UIStepper *)sender {
    [self updateCartWithNumberOfShirts:sender.value];
}

- (IBAction)beginPayment:(id)sender {
    NSString *merchantId = @"<#Replace me with your Apple Merchant ID #>";

    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:merchantId
                                                                             amount:self.amount
                                                                           currency:@"USD"
                                                                        description:@"Premium Llama Food"];
    [paymentRequest setRequiredShippingAddressFields:PKAddressFieldPostalAddress];
    [paymentRequest setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
    PKShippingMethod *shippingMethod = [PKShippingMethod summaryItemWithLabel:@"Llama Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
    [paymentRequest setShippingMethods:@[shippingMethod]];
    paymentRequest.paymentSummaryItems = [self summaryItemsForShippingMethod:shippingMethod];
    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
#if DEBUG
        STPTestPaymentAuthorizationViewController *auth = [[STPTestPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
#else
        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
#endif
        auth.delegate = self;
        [self presentViewController:auth animated:YES completion:nil];
    }
    else {
        PaymentViewController *paymentViewController = [[PaymentViewController alloc] initWithNibName:nil bundle:nil];
        paymentViewController.amount = self.amount;
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentViewController];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingAddress:(ABRecordRef)address
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray *shippingMethods, NSArray *summaryItems))completion {
    [self fetchShippingCostsForAddress:address completion:^(NSArray *shippingMethods, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure, nil, nil);
            return;
        }
        completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, [self summaryItemsForShippingMethod:shippingMethods.firstObject]);
    }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray *summaryItems))completion {
    completion(PKPaymentAuthorizationStatusSuccess, [self summaryItemsForShippingMethod:shippingMethod]);
}

- (void)fetchShippingCostsForAddress:(ABRecordRef)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion {
    // you could, for example, go to UPS here and calculate shipping costs to that address.
    ABMultiValueRef addressValues = ABRecordCopyValue(address, kABPersonAddressProperty);
    NSString *country;
    if (ABMultiValueGetCount(addressValues) > 0) {
        CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
        country = CFDictionaryGetValue(dict, kABPersonAddressCountryKey);
    }
    if (!country) {
        completion(nil, [NSError new]);
    }
    if ([country isEqualToString:@"US"]) {
        PKPaymentSummaryItem *normalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Llama Domestic Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
        PKPaymentSummaryItem *expressItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Llama Domestic Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"30.00"]];
        completion(@[normalItem, expressItem], nil);
    }
    else {
        PKPaymentSummaryItem *normalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Llama International Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"40.00"]];
        PKPaymentSummaryItem *expressItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Llama International Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"50.00"]];
        completion(@[normalItem, expressItem], nil);
    }
}

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *foodItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Premium Llama food" amount:self.amount];
    NSDecimalNumber *total = [foodItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Llama Food Services, Inc." amount:total];
    return @[foodItem, shippingMethod, totalItem];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    void(^tokenBlock)(STPToken *token, NSError *error) = ^void(STPToken *token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        [self createBackendChargeWithToken:token completion:completion];
    };
#if DEBUG
    STPCard *card = [STPCard new];
    card.number = payment.stp_testCardNumber;
    card.expMonth = 12;
    card.expYear = 2020;
    card.cvc = @"123";
    [Stripe createTokenWithCard:card completion:tokenBlock];
#else
    [Stripe createTokenWithPayment:payment
                    operationQueue:[NSOperationQueue mainQueue]
                        completion:tokenBlock];
#endif
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    void(^tokenBlock)(STPToken *token, NSError *error) = ^void(STPToken *token, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        [self createBackendChargeWithToken:token completion:completion];
    };
#if DEBUG
    if (payment.stp_testCardNumber) {
        STPCard *card = [STPCard new];
        card.number = payment.stp_testCardNumber;
        card.expMonth = 12;
        card.expYear = 2020;
        card.cvc = @"123";
        [Stripe createTokenWithCard:card completion:tokenBlock];
        return;
    }
#endif
    [Stripe createTokenWithPayment:payment
                    operationQueue:[NSOperationQueue mainQueue]
                        completion:tokenBlock];
}

- (void)createBackendChargeWithToken:(STPToken *)token
                          completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    if (!ParseApplicationId || !ParseClientKey) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Todo: Submit this token to your backend"
                                                          message:[NSString stringWithFormat:@"Good news! Stripe turned your credit card into a token: %@ \nYou can follow the instructions in the README to set up Parse as an example backend, or use this token to manually create charges at dashboard.stripe.com .", token.tokenId]
                                                         delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                                otherButtonTitles:nil];
        
        [message show];
        [self updateCartWithNumberOfShirts:0];
        completion(PKPaymentAuthorizationStatusSuccess);
        return;
    }
    NSDictionary *chargeParams = @{
                                   @"token": token.tokenId,
                                   @"currency": @"usd",
                                   @"amount": @"1000", // this is in cents (i.e. $10)
                                   };
    // This passes the token off to our payment backend, which will then actually complete charging the card using your account's
    [PFCloud callFunctionInBackground:@"charge" withParameters:chargeParams block:^(id object, NSError *error) {
        if (error) {
            completion(PKPaymentAuthorizationStatusFailure);
        }
        else {
            // We're done!
            [self updateCartWithNumberOfShirts:0];
            completion(PKPaymentAuthorizationStatusSuccess);
            [[[UIAlertView alloc] initWithTitle:@"Payment Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        }
    }];
}


- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
