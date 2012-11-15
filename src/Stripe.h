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

typedef void (^STPSuccessBlock)(STPToken*);
typedef void (^STPErrorBlock)(NSError*);

// Stripe is a static class used to create and retrieve tokens.
@interface Stripe : NSObject

/*
 If you set a default publishable key, it will be used in any of the methods
 below that do not accept a publishable key parameter
 */
+ (NSString *)defaultPublishableKey;
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)createTokenWithCard:(STPCard *)card success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)requestTokenWithID:(NSString *)tokenId publishableKey:(NSString *)publishableKey success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)requestTokenWithID:(NSString *)tokenId operationQueue:(NSOperationQueue *)queue success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;

+ (void)requestTokenWithID:(NSString *)tokenId success:(STPSuccessBlock)successHandler error:(STPErrorBlock)errorHandler;
@end
