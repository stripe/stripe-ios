//
//  Stripe.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 10/30/12.
//  Copyright (c) 2012 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPToken;
@class STPCard;

// Stripe is a static class used to create and retrieve tokens.
@interface Stripe : NSObject

/*
 If you set a default publishable key, it will be used in any of the methods
 below that do not accept a publishable key parameter
 */
+ (NSString *)defaultPublishableKey;
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)createTokenWithCard:(STPCard *)card completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)getTokenWithId:(NSString *)tokenId publishableKey:(NSString *)publishableKey operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)getTokenWithId:(NSString *)tokenId publishableKey:(NSString *)publishableKey completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)getTokenWithId:(NSString *)tokenId operationQueue:(NSOperationQueue *)queue completionHandler:(void (^)(STPToken*, NSError*))handler;

+ (void)getTokenWithId:(NSString *)tokenId completionHandler:(void (^)(STPToken*, NSError*))handler;
@end
