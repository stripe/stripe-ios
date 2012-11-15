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
@property (readonly) NSString *tokenId;
@property (readonly) NSString *object;
@property (readonly) BOOL livemode;
@property (readonly) STPCard *card;
@property (readonly) NSDate *created;
@property (readonly) BOOL used;

/*
 This method should not be invoked in your code.  This is used by Stripe to
 create tokens using a Stripe API response
 */
- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;
@end
