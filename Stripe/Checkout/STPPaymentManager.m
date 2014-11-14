//
//  STPPaymentManager.m
//  Stripe
//
//  Created by Jack Flintermann on 11/11/14.
//
//

#import "STPPaymentManager.h"

@implementation STPPaymentManager

- (void)requestPaymentWithOptions:(STPCheckoutOptions *)options
     fromPresentingViewController:(UIViewController *)presentingViewController
                       completion:(void (^)(STPToken *token, NSError *error, STPPaymentCompletionHandler handler))completion {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)
    if () { // request has required billing address and we can't do applepay
        completion(nil, [NSError new], nil);
    }
#endif
    // do regular checkout things
}

@end
