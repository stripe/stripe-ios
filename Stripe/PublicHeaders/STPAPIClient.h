//
//  STPAPIClient.h
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const STPSDKVersion = @"3.0.0";

@class STPBankAccount, STPCard, STPToken;

/**
 *  A callback to be run with the response from the Stripe API.
 *
 *  @param token The Stripe token from the response. Will be nil if an error occurs. @see STPToken
 *  @param error The error returned from the response, or nil in one occurs. @see StripeError.h for possible values.
 */
typedef void (^STPCompletionBlock)(STPToken *token, NSError *error);

/**
 A top-level class that imports the rest of the Stripe SDK. This class used to contain several methods to create Stripe tokens, but those are now deprecated in
 favor of STPAPIClient.
 */
@interface Stripe : NSObject

/**
 *  Set your Stripe API key with this method. New instances of STPAPIClient will be initialized with this value. You should call this method as early as
 *  possible in your application's lifecycle, preferably in your AppDelegate.
 *
 *  @param   publishableKey Your publishable key, obtained from https://stripe.com/account/apikeys
 *  @warning Make sure not to ship your test API keys to the App Store! This will log a warning if you use your test key in a release build.
 */
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;

/// The current default publishable key.
+ (NSString *)defaultPublishableKey;
@end

/// A client for making connections to the Stripe API.
@interface STPAPIClient : NSObject

/**
 *  A shared singleton API client. Its API key will be initially equal to [Stripe defaultPublishableKey].
 */
+ (instancetype)sharedClient;
- (instancetype)initWithPublishableKey:(NSString *)publishableKey NS_DESIGNATED_INITIALIZER;

/**
 *  @see [Stripe setDefaultPublishableKey:]
 */
@property (nonatomic, copy) NSString *publishableKey;

/**
 *  The operation queue on which to run the url connection and delegate methods. Cannot be nil. @see NSURLConnection
 */
@property (nonatomic) NSOperationQueue *operationQueue;

@end

#pragma mark - Bank Accounts

@interface STPAPIClient (BankAccounts)

/**
 *  Converts an STPBankAccount object into a Stripe token using the Stripe API.
 *
 *  @param bankAccount The user's bank account details. Cannot be nil. @see https://stripe.com/docs/api#create_bank_account_token
 *  @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)completion;

@end

#pragma mark - Credit Cards

@interface STPAPIClient (CreditCards)

/**
 *  Converts an STPCard object into a Stripe token using the Stripe API.
 *
 *  @param card        The user's card details. Cannot be nil. @see https://stripe.com/docs/api#create_card_token
 *  @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)completion;

@end

// These methods are used internally and exposed here only for the sake of writing tests more easily. You should not use them in your own application.
@interface STPAPIClient (PrivateMethods)

- (void)createTokenWithData:(NSData *)data completion:(STPCompletionBlock)completion;

+ (NSData *)formEncodedDataForBankAccount:(STPBankAccount *)bankAccount;

+ (NSData *)formEncodedDataForCard:(STPCard *)card;

+ (NSString *)stringByURLEncoding:(NSString *)string;

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input;

+ (NSString *)SHA1FingerprintOfData:(NSData *)data;

@end
