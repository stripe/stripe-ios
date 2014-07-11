//
//  STPToken.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import <Foundation/Foundation.h>

@class STPCard;

/*
 STPTokens get created by calls to + [Stripe createTokenWithCard:] and + [Stripe getTokenWithId:].  You should not construct these yourself.
 */
@interface STPToken : NSObject

@property (nonatomic, readonly) NSString *tokenId;
@property (nonatomic, readonly) NSString *object;
@property (nonatomic, readonly) BOOL livemode;
@property (nonatomic, readonly) STPCard *card;
@property (nonatomic, readonly) NSDate *created;
@property (nonatomic, readonly) BOOL used;

- (void)postToURL:(NSURL *)url withParams:(NSDictionary *)params completion:(void (^)(NSURLResponse *, NSData *, NSError *))handler;

/*
 This method should not be invoked in your code.  This is used by Stripe to
 create tokens using a Stripe API response
 */
- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;

@end
