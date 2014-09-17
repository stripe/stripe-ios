//
//  Stripe.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StripeError.h"
#import "STPCard.h"
#import "STPToken.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
#import <PassKit/PassKit.h>
#endif

FOUNDATION_EXPORT NSString *const kStripeiOSVersion; // Version of this library.

typedef void (^STPCompletionBlock)(STPToken *token, NSError *error);

// Stripe is a static class used to create and retrieve tokens.
@interface Stripe : NSObject

/*
 If you set a default publishable key, it will be used in any of the methods
 below that do not accept a publishable key parameter
 */
+ (NSString *)defaultPublishableKey;
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler;

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler;

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler;

+ (void)requestTokenWithID:(NSString *)tokenId operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

+ (void)requestTokenWithID:(NSString *)tokenId completion:(STPCompletionBlock)handler;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

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

#endif

@end
