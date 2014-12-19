//
//  STPAPIClient.h
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STPToken;

typedef void (^STPCompletionBlock)(STPToken *token, NSError *error);

@interface Stripe : NSObject
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;
+ (NSString *)defaultPublishableKey;
@end

@interface STPAPIClient : NSObject

+ (instancetype)sharedClient;
- (instancetype)initWithPublishableKey:(NSString *)publishableKey NS_DESIGNATED_INITIALIZER;

@property (nonatomic, copy) NSString *publishableKey;
@property (nonatomic) NSOperationQueue *operationQueue;

- (void)createTokenWithData:(NSData *)data completion:(STPCompletionBlock)completion;

@end

@interface STPAPIClient (PrivateMethods)
+ (NSString *)stringByURLEncoding:(NSString *)string;
+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input;
+ (NSString *)SHA1FingerprintOfData:(NSData *)data;
@end
