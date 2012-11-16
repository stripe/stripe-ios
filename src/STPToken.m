//
//  STPToken.m
//  Stripe
//
//  Created by Saikat Chakrabarti on 11/5/12.
//
//

#import "STPToken.h"
#import "STPCard.h"

@implementation STPToken
@synthesize tokenId, object, livemode, card, created, used;
- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary
{
    if (self = [super init])
    {
        tokenId = [attributeDictionary valueForKey:@"id"];
        object = [attributeDictionary valueForKey:@"object"];
        livemode = [[attributeDictionary objectForKey:@"livemode"] boolValue];
        created = [NSDate dateWithTimeIntervalSince1970:[[attributeDictionary objectForKey:@"created"] doubleValue]];
        used = [[attributeDictionary objectForKey:@"used"] boolValue];
        card = [[STPCard alloc] initWithAttributeDictionary:[attributeDictionary objectForKey:@"card"]];
    }
    return self;
}
@end
