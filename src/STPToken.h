//
//  STPToken.h
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import <Foundation/Foundation.h>

@class STPCard;
@interface STPToken : NSObject
@property (readonly) NSString *tokenId;
@property (readonly) NSString *object;
@property (readonly) BOOL livemode;
@property (readonly) STPCard *card;
@property (readonly) NSDate *created;
@property (readonly) BOOL used;

- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary;
@end
