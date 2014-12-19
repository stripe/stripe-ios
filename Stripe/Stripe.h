//
//  Stripe.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StripeError.h"
#import "STPAPIClient.h"

@class Stripe, STPCard, STPBankAccount;

// Stripe is a static class used to create and retrieve tokens.
@interface Stripe (DeprecatedMethods)

/*
 If you set a default publishable key, it will be used in any of the methods
 below that do not accept a publishable key parameter
 */
+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler;

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

+ (void)createTokenWithCard:(STPCard *)card
             publishableKey:(NSString *)publishableKey
             operationQueue:(NSOperationQueue *)queue
                 completion:(STPCompletionBlock)handler;

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)handler;

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler;

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler;

+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount
                    publishableKey:(NSString *)publishableKey
                    operationQueue:(NSOperationQueue *)queue
                        completion:(STPCompletionBlock)handler;

@end

@interface STPUtils : NSObject

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input;
+ (NSString *)stringByURLEncoding:(NSString *)string;

@end
