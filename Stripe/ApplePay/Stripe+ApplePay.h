//
//  Stripe+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#if defined(STRIPE_ENABLE_APPLEPAY)

#import <PassKit/PassKit.h>
#import "STPAPIClient+ApplePay.h"
@class Stripe;

@interface Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest;

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier;

+ (void)createTokenWithPayment:(PKPayment *)payment completion:(STPCompletionBlock)handler;

+ (void)createTokenWithPayment:(PKPayment *)payment operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

@end

#endif
