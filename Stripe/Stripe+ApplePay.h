//
//  Stripe+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
#import "Stripe.h"
#import <PassKit/PassKit.h>

@interface Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest;

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier
                                                    amount:(NSDecimalNumber *)amount
                                                  currency:(NSString *)currency
                                               description:(NSString *)description;

+ (UIViewController *)paymentControllerWithRequest:(PKPaymentRequest *)request
                                          delegate:(id<PKPaymentAuthorizationViewControllerDelegate>)delegate;

+ (void)createTokenWithPayment:(PKPayment *)payment
                    completion:(STPCompletionBlock)handler;

+ (void)createTokenWithPayment:(PKPayment *)payment
                operationQueue:(NSOperationQueue *)queue
                    completion:(STPCompletionBlock)handler;

@end

#endif