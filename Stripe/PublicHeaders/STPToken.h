//
//  STPToken.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import <Foundation/Foundation.h>
#import "STPNullabilityMacros.h"

@class STPCard;
@class STPBankAccount;

/**
 *  A token returned from submitting payment details to the Stripe API. You should not have to instantiate one of these directly.
 */
@interface STPToken : NSObject

/**
 *  You cannot directly instantiate an STPToken. You should only use one that has been returned from an STPAPIClient callback.
 */
- (stp_nonnull instancetype) init __attribute__((unavailable("You cannot directly instantiate an STPToken. You should only use one that has been returned from an STPAPIClient callback.")));

/**
 *  The value of the token. You can store this value on your server and use it to make charges and customers. @see
 * https://stripe.com/docs/mobile/ios#sending-tokens
 */
@property (nonatomic, readonly, stp_nonnull) NSString *tokenId;

/**
 *  Whether or not this token was created in livemode. Will be YES if you used your Live Publishable Key, and NO if you used your Test Publishable Key.
 */
@property (nonatomic, readonly) BOOL livemode;

/**
 *  The credit card details that were used to create the token. Will only be set if the token was created via a credit card or Apple Pay, otherwise it will be
 * nil.
 */
@property (nonatomic, readonly, stp_nullable) STPCard *card;

/**
 *  The bank account details that were used to create the token. Will only be set if the token was created with a bank account, otherwise it will be nil.
 */
@property (nonatomic, readonly, stp_nullable) STPBankAccount *bankAccount;

/**
 *  When the token was created.
 */
@property (nonatomic, readonly, stp_nullable) NSDate *created;

typedef void (^STPCardServerResponseCallback)(NSURLResponse * __stp_nullable response, NSData * __stp_nullable data, NSError * __stp_nullable error);

/**
 *  Form-encode the token and post those parameters to your backend URL.
 *
 *  @param url     the URL to upload the token details to
 *  @param params  optional parameters to additionally include in the POST body
 *  @param handler code to execute with your server's response
 *  @deprecated    you should write your own networking code to talk to your server.
 */
- (void)postToURL:(stp_nonnull NSURL *)url withParams:(stp_nullable NSDictionary *)params completion:(stp_nullable STPCardServerResponseCallback)handler __attribute((deprecated));

@end

// This method is used internally by Stripe to deserialize API responses and exposed here for convenience and testing purposes only. You should not use it in
// your own code.
@interface STPToken (PrivateMethods)

- (stp_nonnull instancetype)initWithAttributeDictionary:(stp_nonnull NSDictionary *)attributeDictionary;

@end
