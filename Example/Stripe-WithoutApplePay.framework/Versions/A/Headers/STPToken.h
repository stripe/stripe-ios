//
//  STPToken.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import <Foundation/Foundation.h>

@class STPCard;
@class STPBankAccount;

/**
 *  A token returned from submitting payment details to the Stripe API. You should not have to instantiate one of these directly.
 */
@interface STPToken : NSObject

/**
 *  The value of the token. You can store this value on your server and use it to make charges and customers. @see
 * https://stripe.com/docs/mobile/ios#sending-tokens
 */
@property (nonatomic, readonly) NSString *tokenId;

/**
 *  Whether or not this token was created in livemode. Will be YES if you used your Live Publishable Key, and NO if you used your Test Publishable Key.
 */
@property (nonatomic, readonly) BOOL livemode;

/**
 *  The credit card details that were used to create the token. Will only be set if the token was created via a credit card or Apple Pay, otherwise it will be
 * nil.
 */
@property (nonatomic, readonly) STPCard *card;

/**
 *  The bank account details that were used to create the token. Will only be set if the token was created with a bank account, otherwise it will be nil.
 */
@property (nonatomic, readonly) STPBankAccount *bankAccount;

/**
 *  When the token was created.
 */
@property (nonatomic, readonly) NSDate *created;

typedef void (^STPCardServerResponseCallback)(NSURLResponse *response, NSData *data, NSError *error);

/**
 *  Form-encode the token and post those parameters to your backend URL.
 *
 *  @param url     the URL to upload the token details to
 *  @param params  optional parameters to additionally include in the POST body
 *  @param handler code to execute with your server's response
 *  @deprecated    you should write your own networking code to talk to your server.
 */
- (void)postToURL:(NSURL *)url withParams:(NSDictionary *)params completion:(STPCardServerResponseCallback)handler __attribute((deprecated));

@end

// This method is used internally by Stripe to deserialize API responses and exposed here for convenience and testing purposes only. You should not use it in
// your own code.
@interface STPToken (PrivateMethods)

- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;

@end
