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

/*
 STPTokens get created by calls to + [Stripe createTokenWithCard:], + [Stripe createTokenWithBankAccount:], and + [Stripe getTokenWithId:].  You should not
 construct these yourself.
 */
@interface STPToken : NSObject

@property (nonatomic, readonly) NSString *tokenId;
@property (nonatomic, readonly) NSString *object;
@property (nonatomic, readonly) BOOL livemode;
@property (nonatomic, readonly) STPCard *card;
@property (nonatomic, readonly) STPBankAccount *bankAccount;
@property (nonatomic, readonly) NSDate *created;
@property (nonatomic, readonly) BOOL used;

typedef void (^STPCardServerResponseCallback)(NSURLResponse *response, NSData *data, NSError *error);

- (void)postToURL:(NSURL *)url withParams:(NSDictionary *)params completion:(STPCardServerResponseCallback)handler;

/*
 This method should not be invoked in your code.  This is used by Stripe to
 create tokens using a Stripe API response
 */
- (instancetype)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;

@end
