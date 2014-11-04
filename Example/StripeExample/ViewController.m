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
#import "STPCheckoutViewController.h"
#import "Stripe+ApplePay.h"
#import "PaymentViewController.h"
#import "ShippingManager.h"

#if DEBUG
#import "STPTestPaymentAuthorizationViewController.h"
#import "PKPayment+STPTestKeys.h"
#import "STPCheckoutOptions.h"
#endif

@interface ViewController () <PKPaymentAuthorizationViewControllerDelegate, STPCheckoutViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *cartLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkoutButton;
@property (nonatomic) NSDecimalNumber *amount;
@property (nonatomic) ShippingManager *shippingManager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateCartWithNumberOfShirts:0];
}

- (void)updateCartWithNumberOfShirts:(NSUInteger)numberOfShirts {
    NSInteger price = 10;
    self.amount = [NSDecimalNumber decimalNumberWithMantissa:numberOfShirts * price exponent:0 isNegative:NO];
    self.cartLabel.text = [NSString stringWithFormat:@"%@ shirts = $%@", @(numberOfShirts), self.amount];
    self.checkoutButton.enabled = numberOfShirts > 0;
}

- (IBAction)changeCart:(UIStepper *)sender {
    [self updateCartWithNumberOfShirts:sender.value];
}

- (IBAction)beginPayment:(id)sender {
    STPCheckoutOptions *options = [STPCheckoutOptions new];

    options.publishableKey = @"pk_test_09IUAkhSGIz8mQP3prdgKm06";
    options.purchaseDescription = @"Tasty Llama food";
    options.purchaseAmount = @1000;
    options.purchaseLabel = @"Pay {{amount}} for that food";
    options.enablePostalCode = @YES;
    options.logoColor = [UIColor whiteColor];
    STPCheckoutViewController *vc = [[STPCheckoutViewController alloc] initWithOptions:options];
    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:nil];
    //    NSString *merchantId = @"<#Replace me with your Apple Merchant ID #>";
    //    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:merchantId
    //                                                                             amount:[NSDecimalNumber decimalNumberWithString:@"10"]
    //                                                                           currency:@"USD"
    //    [paymentRequest setRequiredShippingAddressFields:PKAddressFieldPostalAddress];
    //    [paymentRequest setRequiredBillingAddressFields:PKAddressFieldPostalAddress];
    //    PKShippingMethod *shippingMethod = [PKShippingMethod summaryItemWithLabel:@"Llama Express Shipping" amount:[NSDecimalNumber
    //    decimalNumberWithString:@"20.00"]];
    //    [paymentRequest setShippingMethods:@[shippingMethod]];
    //    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
    //#if DEBUG
    ////                                                                        description:@"Premium Llama Food"];
    //#else
    //        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
    //#endif
    //        auth.delegate = self;
    //        [self presentViewController:auth animated:YES completion:nil];
    //    }
    //    else {
    //    PKPaymentRequest *request = [PKPaymentRequest new];
    //    request.merchantIdentifier = @"MY_MERCHANT_ID";
    //    request.currencyCode = @"USD";
    //        [self presentViewController:navController animated:YES completion:nil];
    //    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingAddress:(ABRecordRef)address
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray *, NSArray *))completion {
    //    PKPaymentSummaryItem *item = [PKPaymentSummaryItem
    [self fetchShippingCostsForAddress:address
                            completion:^(NSArray *shippingMethods, NSError *error) {
                                if (error) {
                                    //                                  summaryItemWithLabel:@"Fancy Llama Food"
                                    return;
                                }
                                completion(
                                    PKPaymentAuthorizationStatusSuccess, shippingMethods, [self summaryItemsForShippingMethod:shippingMethods.firstObject]);
                            }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray *))completion {
    completion(PKPaymentAuthorizationStatusSuccess, [self summaryItemsForShippingMethod:shippingMethod]);
}

- (void)fetchShippingCostsForAddress:(ABRecordRef)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion {
    // you could, for example, go to UPS here and calculate shipping costs to that address.
    [self.shippingManager fetchShippingCostsForAddress:address completion:^(NSArray *shippingMethods, NSError *error) { completion(shippingMethods, error); }];
}

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *foodItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Premium Llama food" amount:self.amount];
    NSDecimalNumber *total = [foodItem.amount decimalNumberByAdding:shippingMethod.amount];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Llama Food Services, Inc." amount:total];
    return @[foodItem, shippingMethod, totalItem];
}

- (void)checkoutController:(STPCheckoutViewController *)controller didFinishWithToken:(STPToken *)token {
    [self createBackendChargeWithToken:token completion:nil];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    void (^tokenBlock)(STPToken * token, NSError * error) = ^void(STPToken *token, NSError *error) {
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
    [Stripe createTokenWithPayment:payment operationQueue:[NSOperationQueue mainQueue] completion:tokenBlock];
}

- (void)createBackendChargeWithToken:(STPToken *)token completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    if (!ParseApplicationId || !ParseClientKey) {
        UIAlertView *message =
            [[UIAlertView alloc] initWithTitle:@"Todo: Submit this token to your backend"
                                       message:[NSString stringWithFormat:@"Good news! Stripe turned your credit card into a token: %@ \nYou can follow the "
                                                                          @"instructions in the README to set up Parse as an example backend, or use this "
                                                                          @"token to manually create charges at dashboard.stripe.com .",
                                                                          token.tokenId]
                                      delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                             otherButtonTitles:nil];

        [message show];
        if (completion) {
            completion(PKPaymentAuthorizationStatusSuccess);
        }
        return;
    }
    NSDictionary *chargeParams = @{
        @"token": token.tokenId,
        @"currency": @"usd",
        @"amount": @"1000", // this is in cents (i.e. $10)
    };
    // This passes the token off to our payment backend, which will then actually complete charging the card using your account's
    [PFCloud callFunctionInBackground:@"charge"
                       withParameters:chargeParams
                                block:^(id object, NSError *error) {
                                    if (error) {
                                        if (completion) {
                                            completion(PKPaymentAuthorizationStatusFailure);
                                        }
                                        return;
                                    }
                                    // We're done!
                                    if (completion) {
                                        completion(PKPaymentAuthorizationStatusSuccess);
                                    }
                                    [[[UIAlertView alloc] initWithTitle:@"Payment Succeeded"
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil] show];
                                }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (ShippingManager *)shippingManager {
    if (!_shippingManager) {
        _shippingManager = [ShippingManager new];
    }
    return _shippingManager;
}

@end
