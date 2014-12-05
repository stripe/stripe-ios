//
//  Stripe+ApplePay.h
//  Stripe
//
//  Created by Jack Flintermann on 9/17/14.
//
//

#ifdef STRIPE_ENABLE_APPLEPAY

#import "Stripe.h"
#import <PassKit/PassKit.h>

@class PKPaymentRequest;

@interface STPToken (ApplePayAdditions)
@property (nonatomic, readonly) PKPayment *payment;
@end

@interface Stripe (ApplePay)

+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest;

+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier;

+ (void)createTokenWithPayment:(PKPayment *)payment completion:(STPCompletionBlock)handler;

+ (void)createTokenWithPayment:(PKPayment *)payment operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

@end

#endif
