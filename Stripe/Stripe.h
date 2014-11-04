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
#import "STPBankAccount.h"
#import "STPToken.h"

extern NSString *const STPLibraryVersionNumber; // Version of this library.
extern NSString *const STPUserAgentFieldName; // We set our own custom HTTP header field on requests to better understand library usage.


typedef void (^STPCompletionBlock)(STPToken *token, NSError *error);

// Stripe is a static class used to create and retrieve tokens.
@interface Stripe : NSObject

/*
 If you set a default publishable key, it will be used in any of the methods
 below that do not accept a publishable key parameter
 */
+ (NSString *)defaultPublishableKey;
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;

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

+ (NSDictionary *)stripeUserAgentDetails;

+ (NSURL *)apiURL;
+ (void)handleTokenResponse:(NSURLResponse *)response body:(NSData *)body error:(NSError *)requestError completion:(STPCompletionBlock)handler;

@end
