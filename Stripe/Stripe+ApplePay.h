//
//  Stripe+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#import "Stripe.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)
#import <PassKit/PassKit.h>
#endif

@class PKPaymentRequest;

@interface Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest;

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier
                                                    amount:(NSDecimalNumber *)amount
                                                  currency:(NSString *)currency
                                               description:(NSString *)description;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)

+ (UIViewController *)paymentControllerWithRequest:(PKPaymentRequest *)request
                                          delegate:(id<PKPaymentAuthorizationViewControllerDelegate>)delegate;

+ (void)createTokenWithPayment:(PKPayment *)payment
                    completion:(STPCompletionBlock)handler;

+ (void)createTokenWithPayment:(PKPayment *)payment
                operationQueue:(NSOperationQueue *)queue
                    completion:(STPCompletionBlock)handler;

#endif

@end
