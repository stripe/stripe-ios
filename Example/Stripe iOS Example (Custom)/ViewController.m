//
//  ViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 8/21/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <Stripe/Stripe.h>

#import "ViewController.h"
#import "PaymentViewController.h"
#import "Constants.h"
#import "ShippingManager.h"

@interface ViewController () <PaymentViewControllerDelegate, STPCheckoutViewControllerDelegate, PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic) BOOL applePaySucceeded;
@property (nonatomic) NSError *applePayError;
@property (nonatomic) ShippingManager *shippingManager;
@property (weak, nonatomic) IBOutlet UIButton *applePayButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shippingManager = [[ShippingManager alloc] init];
    self.applePayButton.enabled = [self applePayEnabled];
}

- (void)presentError:(NSError *)error {
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                      message:[error localizedDescription]
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                            otherButtonTitles:nil];
    [message show];
}

- (void)paymentSucceeded {
    [[[UIAlertView alloc] initWithTitle:@"Success!"
                                message:@"Payment successfully created!"
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

#pragma mark - Apple Pay

- (BOOL)applePayEnabled {
    if ([PKPaymentRequest class]) {
        PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:AppleMerchantId];
        return [Stripe canSubmitPaymentRequest:paymentRequest];
    }
    return NO;
}

- (IBAction)beginApplePay:(id)sender {
    self.applePaySucceeded = NO;
    self.applePayError = nil;

    NSString *merchantId = AppleMerchantId;

    PKPaymentRequest *paymentRequest = [Stripe paymentRequestWithMerchantIdentifier:merchantId];
    if ([Stripe canSubmitPaymentRequest:paymentRequest]) {
        paymentRequest.paymentSummaryItems = [self summaryItemsForShippingMethod:paymentRequest.shippingMethods.firstObject];
        PKPaymentAuthorizationViewController *auth = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
        auth.delegate = self;
        [self presentViewController:auth animated:YES completion:nil];
    }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingAddress:(ABRecordRef)address
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray<PKShippingMethod *> *shippingMethods, NSArray<PKPaymentSummaryItem *> *summaryItems))completion {
    [self.shippingManager fetchShippingCostsForAddress:address
                                            completion:^(NSArray *shippingMethods, NSError *error) {
                                                if (error) {
                                                    completion(PKPaymentAuthorizationStatusFailure, nil, nil);
                                                    return;
                                                }
                                                completion(PKPaymentAuthorizationStatusSuccess,
                                                           shippingMethods,
                                                           [self summaryItemsForShippingMethod:shippingMethods.firstObject]);
                                            }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> *summaryItems))completion {
    completion(PKPaymentAuthorizationStatusSuccess, [self summaryItemsForShippingMethod:shippingMethod]);
}

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    PKPaymentSummaryItem *shirtItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Cool Shirt" amount:[NSDecimalNumber decimalNumberWithString:@"10.00"]];
    PKPaymentSummaryItem *totalItem = [PKPaymentSummaryItem summaryItemWithLabel:@"Stripe Shirt Shop" amount:shirtItem.amount];
    return @[shirtItem, totalItem];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [[STPAPIClient sharedClient] createTokenWithPayment:payment
                                             completion:^(STPToken *token, NSError *error) {
                                                 [self createBackendChargeWithToken:token
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
    if (self.applePaySucceeded) {
        [self paymentSucceeded];
    } else if (self.applePayError) {
        [self presentError:self.applePayError];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    self.applePaySucceeded = NO;
    self.applePayError = nil;
}

#pragma mark - Stripe Checkout

- (IBAction)beginStripeCheckout:(id)sender {
    STPCheckoutOptions *options = [[STPCheckoutOptions alloc] initWithPublishableKey:[Stripe defaultPublishableKey]];
    options.purchaseDescription = @"Cool Shirt";
    options.purchaseAmount = 1000; // this is in cents
    options.logoColor = [UIColor purpleColor];
    STPCheckoutViewController *checkoutViewController = [[STPCheckoutViewController alloc] initWithOptions:options];
    checkoutViewController.checkoutDelegate = self;
    [self presentViewController:checkoutViewController animated:YES completion:nil];
}

- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    [self createBackendChargeWithToken:token completion:completion];
}

- (void)checkoutController:(STPCheckoutViewController *)controller didFinishWithStatus:(STPPaymentStatus)status error:(NSError *)error {
    switch (status) {
    case STPPaymentStatusSuccess:
        [self paymentSucceeded];
        break;
    case STPPaymentStatusError:
        [self presentError:error];
        break;
    case STPPaymentStatusUserCancelled:
        // do nothing
        break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Custom Credit Card Form

- (IBAction)beginCustomPayment:(id)sender {
    PaymentViewController *paymentViewController = [[PaymentViewController alloc] initWithNibName:nil bundle:nil];
    paymentViewController.amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    paymentViewController.backendCharger = self;
    paymentViewController.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:paymentViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)paymentViewController:(PaymentViewController *)controller didFinish:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (error) {
        [self presentError:error];
    } else {
        [self paymentSucceeded];
    }
}

#pragma mark - STPBackendCharging

- (void)createBackendChargeWithToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    NSDictionary *chargeParams = @{ @"stripeToken": token.tokenId, @"amount": @"1000" };

    if (!BackendChargeURLString) {
        NSError *error = [NSError
            errorWithDomain:StripeDomain
                       code:STPInvalidRequestError
                   userInfo:@{
                       NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Good news! Stripe turned your credit card into a token: %@ \nYou can follow the "
                                                                             @"instructions in the README to set up an example backend, or use this "
                                                                             @"token to manually create charges at dashboard.stripe.com .",
                                                                             token.tokenId]
                   }];
        completion(STPBackendChargeResultFailure, error);
        return;
    }

    // This passes the token off to our payment backend, which will then actually complete charging the card using your Stripe account's secret key
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager POST:[BackendChargeURLString stringByAppendingString:@"/charge"]
        parameters:chargeParams
        success:^(AFHTTPRequestOperation *operation, id responseObject) { completion(STPBackendChargeResultSuccess, nil); }
        failure:^(AFHTTPRequestOperation *operation, NSError *error) { completion(STPBackendChargeResultFailure, error); }];
}

@end
