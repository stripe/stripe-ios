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
#import "STPCard.h"
#import "STPBankAccount.h"
#import "STPToken.h"

@class Stripe, STPCard, STPBankAccount;

// These methods are deprecated. You should instead use STPAPIClient to create tokens.
// Example: [Stripe createTokenWithCard:card completion:completion];
// becomes [[STPAPIClient sharedClient] createTokenWithCard:card completion:completion];
@interface Stripe (Deprecated)

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user. The URL
 *connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param card    The user's card details. @see STPCard
 *  @param handler Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated    Use STPAPIClient instead.
 */
+ (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user. The URL
 *connection will run on the main queue.
 *
 *  @param card           The user's card details. @see STPCard
 *  @param publishableKey The API key to use to authenticate with Stripe. Get this at https://stripe.com/account/apikeys .
 *  @param handler        Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated           Use STPAPIClient instead.
 */
+ (void)createTokenWithCard:(STPCard *)card publishableKey:(NSString *)publishableKey completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user.
 *
 *  @param card    The user's card details. @see STPCard
 *  @param queue   The operation queue on which to run the URL connection. @see NSURLConnection
 *  @param handler Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated    Use STPAPIClient instead.
 */
+ (void)createTokenWithCard:(STPCard *)card operationQueue:(NSOperationQueue *)queue completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user.
 *
 *  @param card           The user's card details. @see STPCard
 *  @param publishableKey The API key to use to authenticate with Stripe. Get this at https://stripe.com/account/apikeys .
 *  @param queue          The operation queue on which to run the URL connection. @see NSURLConnection
 *  @param handler        Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated           Use STPAPIClient instead.
 */
+ (void)createTokenWithCard:(STPCard *)card
             publishableKey:(NSString *)publishableKey
             operationQueue:(NSOperationQueue *)queue
                 completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user. The URL
 *connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param bankAccount The user's bank account details. @see STPBankAccount
 *  @param handler     Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated        Use STPAPIClient instead.
 */
+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user. The URL
 *connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param bankAccount    The user's bank account details. @see STPBankAccount
 *  @param publishableKey The API key to use to authenticate with Stripe. Get this at https://stripe.com/account/apikeys .
 *  @param handler        Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated           Use STPAPIClient instead.
 */
+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount
                    publishableKey:(NSString *)publishableKey
                        completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user. The URL
 *connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param bankAccount The user's bank account details. @see STPBankAccount
 *  @param queue       The operation queue on which to run the URL connection. @see NSURLConnection
 *  @param handler     Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated        Use STPAPIClient instead.
 */
+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount
                    operationQueue:(NSOperationQueue *)queue
                        completion:(STPCompletionBlock)handler __attribute__((deprecated));

/**
 *  Securely convert your user's credit card details into a Stripe token, which you can then safely store on your server and use to charge the user. The URL
 *connection will run on the main queue. Uses the value of [Stripe defaultPublishableKey] for authentication.
 *
 *  @param bankAccount    The user's bank account details. @see STPBankAccount
 *  @param publishableKey The API key to use to authenticate with Stripe. Get this at https://stripe.com/account/apikeys .
 *  @param queue          The operation queue on which to run the URL connection. @see NSURLConnection
 *  @param handler        Code to run when the user's card has been turned into a Stripe token.
 *  @deprecated           Use STPAPIClient instead.
 */
+ (void)createTokenWithBankAccount:(STPBankAccount *)bankAccount
                    publishableKey:(NSString *)publishableKey
                    operationQueue:(NSOperationQueue *)queue
                        completion:(STPCompletionBlock)handler __attribute__((deprecated));

@end
