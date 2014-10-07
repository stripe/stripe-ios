//
//  ViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <PassKit/PassKit.h>
#import <Parse/Parse.h>
#import "ViewController.h"
#import "Stripe.h"
#import "Constants.h"
#import "STPCheckoutViewController.h"
#import "STPCheckoutOptions.h"

@interface ViewController()<PKPaymentAuthorizationViewControllerDelegate, STPCheckoutViewControllerDelegate>
@end

@implementation ViewController

- (IBAction)beginPayment:(id)sender {
    STPCheckoutOptions *options = [STPCheckoutOptions new];
    options.productDescription = @"Tasty Llama food";
    options.purchaseAmount = 1000;
    options.panelLabel = @"Pay {{amount}} for that food";
    STPCheckoutViewController *vc = [[STPCheckoutViewController alloc] initWithOptions:options];
    [self presentViewController:vc animated:YES completion:nil];
//    NSString *merchantId = @"<#Replace me with your Apple Merchant ID #>";
//    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:merchantId
//                                                                             amount:[NSDecimalNumber decimalNumberWithString:@"10"]
//                                                                           currency:@"USD"
//                                                                        description:@"Premium Llama Food"];
//    PKPaymentRequest *request = [PKPaymentRequest new];
//    request.merchantIdentifier = @"MY_MERCHANT_ID";
//    request.currencyCode = @"USD";
//    PKPaymentSummaryItem *item = [PKPaymentSummaryItem
//                                  summaryItemWithLabel:@"Fancy Llama Food"
//                                  amount:@10.00];
//    request.paymentSummaryItems = @[item];
//    
//    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
//        UIViewController *paymentController = [Stripe paymentControllerWithRequest:paymentRequest delegate:self];
//        [self presentViewController:paymentController animated:YES completion:nil];
//    }
//    else {
//        [self performSegueWithIdentifier:@"OldPaymentFlowSegue" sender:sender];
//    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                   completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [Stripe createTokenWithPayment:payment
                    operationQueue:[NSOperationQueue mainQueue]
                        completion:^(STPToken *token, NSError *error) {
                            if (error) {
                                completion(PKPaymentAuthorizationStatusFailure);
                                return;
                            }
                            [self createBackendChargeWithToken:token completion:completion];
                        }];

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
            completion(PKPaymentAuthorizationStatusSuccess);
            [[[UIAlertView alloc] initWithTitle:@"Payment Succeeded" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        }
    }];
}


- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
