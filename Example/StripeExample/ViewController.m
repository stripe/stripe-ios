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
#import "STPPaymentPresenter.h"

#if DEBUG
#import "STPTestPaymentAuthorizationViewController.h"
#import "PKPayment+STPTestKeys.h"
#endif

#import "STPCheckoutOptions.h"

@interface ViewController () <STPPaymentPresenterDelegate>
@property (weak, nonatomic) IBOutlet UILabel *cartLabel;
@property (weak, nonatomic) IBOutlet UIButton *checkoutButton;
@property (nonatomic) NSDecimalNumber *amount;
@property (nonatomic) ShippingManager *shippingManager;
@property (nonatomic) STPPaymentPresenter *paymentPresenter;
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
    options.appleMerchantId = @"<#Replace me with your Apple Merchant ID #>";
    options.purchaseDescription = @"Tasty Llama food";
    options.purchaseAmount = @1000;
    options.purchaseLabel = @"Pay {{amount}} for that food";
    options.enablePostalCode = @YES;
    options.logoColor = [UIColor yellowColor];
    self.paymentPresenter = [[STPPaymentPresenter alloc] initWithCheckoutOptions:options delegate:self];
    [self.paymentPresenter requestPaymentFromPresentingViewController:self];
}

- (void)paymentPresenter:(STPPaymentPresenter *)presenter didCreateStripeToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    [self createBackendChargeWithToken:token completion:completion];
}

- (void)paymentPresenter:(STPPaymentPresenter *)presenter didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    [self dismissViewControllerAnimated:YES
                             completion:^{
                                 if (error) {
                                     // present error
                                 }
                                 if (status == STPPaymentStatusSuccess) {
                                     // yay!
                                 }
                             }];
}

- (void)createBackendChargeWithToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    if (!ParseApplicationId || !ParseClientKey) {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: [NSString
                stringWithFormat:@"You created a token! Its value is %@. Now, you need to configure your Parse backend in order to charge this customer.",
                                 token.tokenId]
        };
        NSError *error = [NSError errorWithDomain:StripeDomain code:STPInvalidRequestError userInfo:userInfo];
        completion(STPBackendChargeResultFailure, error);
        return;
    }
    NSDictionary *chargeParams = @{
        @"token": token.tokenId,
        @"currency": @"usd",
        @"amount": self.amount.stringValue, // this is in cents (i.e. $10)
    };
    // This passes the token off to our payment backend, which will then actually complete charging the card using your account's secret key.
    [PFCloud callFunctionInBackground:@"charge"
                       withParameters:chargeParams
                                block:^(id object, NSError *error) {
                                    if (error) {
                                        if (completion) {
                                            NSLog(@"Error occurred making payment");
                                            completion(STPBackendChargeResultFailure, error);
                                        }
                                        return;
                                    }
                                    // We're done!
                                    if (completion) {
                                        completion(STPBackendChargeResultSuccess, nil);
                                    }
                                }];
}

@end
