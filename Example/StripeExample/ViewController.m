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
#import "ShippingManager.h"
#import "STPCheckoutOptions.h"
#import "STPPaymentManager.h"

#if DEBUG
#import "STPTestPaymentAuthorizationViewController.h"
#import "PKPayment+STPTestKeys.h"
#endif

#import "STPCheckoutOptions.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *cartLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkoutButton;
@property (nonatomic) NSDecimalNumber *amount;
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic) STPPaymentManager *paymentManager;
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
    self.paymentManager = [[STPPaymentManager alloc] init];
    [self.paymentManager requestPaymentWithOptions:options
        fromPresentingViewController:self
        withTokenHandler:^(STPToken *token, STPTokenSubmissionHandler handler) { [self createBackendChargeWithToken:token completion:handler]; }
        completion:^(BOOL success, NSError *error) {
            if (success) {
            } else if (error) {
                // display error
            } else {
                // user canceled the request; do nothing
            }
        }];
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

- (void)createBackendChargeWithToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    if (!ParseApplicationId || !ParseClientKey) {
        completion(STPPaymentAuthorizationStatusFailure);
        return;
    }
    NSDictionary *chargeParams = @{
        @"token": token.tokenId,
        @"currency": @"usd",
        @"amount": @"1000", // this is in cents (i.e. $10)
    };
    // This passes the token off to our payment backend, which will then actually complete charging the card using your account's secret key.
    [PFCloud callFunctionInBackground:@"charge"
                       withParameters:chargeParams
                                block:^(id object, NSError *error) {
                                    if (error) {
                                        if (completion) {
                                            completion(STPPaymentAuthorizationStatusFailure);
                                        }
                                        return;
                                    }
                                    // We're done!
                                    if (completion) {
                                        completion(STPPaymentAuthorizationStatusSuccess);
                                    }
                                }];
}

@end
