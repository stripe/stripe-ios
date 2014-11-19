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

typedef void (^STPPaymentTokenHandler)(STPToken *token, NSError *error, STPPaymentCompletionHandler handler);

@interface STPPaymentManager () <STPCheckoutViewControllerDelegate>
@property (weak, nonatomic) UIViewController *presentingViewController;
@property (copy, nonatomic) STPPaymentTokenHandler tokenHandler;
@end

#if APPLEPAY
@interface STPPaymentManager (ApplePay) <PKPaymentAuthorizationViewControllerDelegate>
@end
#endif

@implementation STPPaymentManager

- (void)requestPaymentWithOptions:(STPCheckoutOptions *)options
     fromPresentingViewController:(UIViewController *)presentingViewController
                 withTokenHandler:(STPPaymentTokenHandler)tokenHandler {
    self.presentingViewController = presentingViewController;
    self.tokenHandler = tokenHandler;
#if APPLEPAY
    if (options.paymentRequest) {
        if (options.paymentRequest.requiredShippingAddressFields != PKAddressFieldNone ||
            options.paymentRequest.requiredShippingAddressFields != PKAddressFieldNone) {
            NSError *error =
                [[NSError alloc] initWithDomain:StripeDomain
                                           code:STPInvalidRequestError
                                       userInfo:@{
                                           NSLocalizedDescriptionKey: NSLocalizedString(
                                               @"Your payment request has required billing or shipping address fields, which isn't supported by Stripe "
                                               @"Checkout yet. You should collect that information ahead of time if you want to use this feature.",
                                               nil),
                                       }];
            self.tokenHandler(nil, error, nil);
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
    self.tokenHandler(nil, error, nil);
}

- (void)checkoutControllerDidCancel:(STPCheckoutViewController *)controller {
    self.tokenHandler(nil, nil, nil);
}

- (void)checkoutController:(STPCheckoutViewController *)controller didFinishWithToken:(STPToken *)token {
    STPPaymentCompletionHandler completion = nil; // todo
    self.tokenHandler(token, nil, completion);
}

#pragma mark - PKPaymentAuthorizatoinViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))pkCompletion {
    [Stripe createTokenWithPayment:payment completion:^(STPToken *token, NSError *error) {
        if (error) {
            self.tokenHandler(nil, error, nil);
        }
        STPPaymentCompletionHandler completion = nil; // todo
        self.tokenHandler(token, nil, completion);
    }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
}

@end
