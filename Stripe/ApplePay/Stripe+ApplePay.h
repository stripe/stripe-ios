//
//  Stripe+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000 && defined(STRIPE_ENABLE_APPLEPAY)

#import "Stripe.h"
#import <PassKit/PassKit.h>

@class PKPaymentRequest;

@interface Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest;

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier;

+ (void)createTokenWithPayment:(PKPayment *)payment completion:(STPCompletionBlock)handler;

+ (void)createTokenWithPayment:(PKPayment *)payment operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

@end

#endif
