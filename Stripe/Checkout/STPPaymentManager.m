//
//  STPPaymentManager.m
//  Stripe
//
//  Created by Jack Flintermann on 11/11/14.
//
//

#define APPLEPAY __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)

#import "STPPaymentManager.h"
#import "STPCheckoutOptions.h"
#import "STPCheckoutViewController.h"
#import "Stripe.h"

#if APPLEPAY
#import "Stripe+ApplePay.h"
#endif

@interface STPPaymentManager () <STPCheckoutViewControllerDelegate>
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (copy, nonatomic) STPPaymentTokenHandler tokenHandler;
@property (copy, nonatomic) STPPaymentCompletionHandler completion;
@end

#if APPLEPAY
@interface STPPaymentManager (ApplePay) <PKPaymentAuthorizationViewControllerDelegate>
@end
#endif

@implementation STPPaymentManager

- (void)requestPaymentWithOptions:(STPCheckoutOptions *)options
     fromPresentingViewController:(UIViewController *)presentingViewController
                 withTokenHandler:(STPPaymentTokenHandler)tokenHandler
                       completion:(STPPaymentCompletionHandler)completion {
    NSCParameterAssert(options);
    NSCParameterAssert(presentingViewController);
    NSCParameterAssert(tokenHandler);
    NSCParameterAssert(completion);
    self.presentingViewController = presentingViewController;
    self.tokenHandler = tokenHandler;
    self.completion = completion;
#if APPLEPAY
    if (options.paymentRequest) {
        if (options.paymentRequest.requiredShippingAddressFields != PKAddressFieldNone) {
            NSError *error = [[NSError alloc] initWithDomain:StripeDomain
                                                        code:STPInvalidRequestError
                                                    userInfo:@{
                                                        NSLocalizedDescriptionKey: NSLocalizedString(
                                                            @"Your payment request has required shipping address fields, which isn't supported by Stripe "
                                                            @"Checkout yet. You should collect that information ahead of time if you want to use this feature.",
                                                            nil),
                                                    }];
            self.completion(NO, error);
            return;
        }
        if ([Stripe canSubmitPaymentRequest:options.paymentRequest]) {
            // do ApplePay things
            PKPaymentAuthorizationViewController *paymentViewController =
                [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:options.paymentRequest];
            paymentViewController.delegate = self;
            [self.presentingViewController presentViewController:paymentViewController animated:YES completion:nil];
            return;
        }
    }
#endif
    STPCheckoutViewController *checkoutViewController = [[STPCheckoutViewController alloc] initWithOptions:options];
    checkoutViewController.delegate = self;
    [self.presentingViewController presentViewController:checkoutViewController animated:YES completion:nil];
}

#pragma mark - STPCheckoutViewControllerDelegate

- (void)checkoutController:(STPCheckoutViewController *)controller didFailWithError:(NSError *)error {
    self.completion(NO, error);
}

- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller {
    self.completion(NO, nil);
}

- (void)checkoutControllerDidFinish:(STPCheckoutViewController *)controller {
    [self.presentingViewController dismissViewControllerAnimated:YES
                                                      completion:^{

                                                      }];
}

- (void)checkoutController:(STPCheckoutViewController *)controller didCreateToken:(STPToken *)token completion:(STPTokenSubmissionHandler)completion {
    STPTokenSubmissionHandler paymentCompletion = ^(STPPaymentAuthorizationStatus status) {
        if (status == STPPaymentAuthorizationStatusSuccess) {
        } else {
        }
    };
    self.tokenHandler(token, paymentCompletion);
}

#if APPLEPAY
#pragma mark - PKPaymentAuthorizatoinViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))pkCompletion {
    [Stripe createTokenWithPayment:payment
                        completion:^(STPToken *token, NSError *error) {
                            if (error) {
                                self.completion(NO, error);
                            }
                            STPTokenSubmissionHandler completion = ^(STPPaymentAuthorizationStatus status) {
                                if (status == STPPaymentAuthorizationStatusSuccess) {
                                    pkCompletion(PKPaymentAuthorizationStatusSuccess);
                                } else {
                                    pkCompletion(PKPaymentAuthorizationStatusFailure);
                                }
                            };
                            self.tokenHandler(token, completion);
                        }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
}

#endif

@end
