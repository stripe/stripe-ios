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
    if (self = [super init]) {
        tokenId = [attributeDictionary valueForKey:@"id"];
        object = [attributeDictionary valueForKey:@"object"];
        livemode = [attributeDictionary[@"livemode"] boolValue];
        created = [NSDate dateWithTimeIntervalSince1970:[attributeDictionary[@"created"] doubleValue]];
        used = [attributeDictionary[@"used"] boolValue];
        card = [[STPCard alloc] initWithAttributeDictionary:attributeDictionary[@"card"]];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%@)", tokenId ?: @"Unknown token", (livemode ? @"live mode" : @"test mode")];
}

- (void)postToURL:(NSURL *)url withParams:(NSMutableDictionary *)params completion:(void (^)(NSURLResponse *, NSData *, NSError *))handler
{

    NSMutableString *body = [NSMutableString stringWithFormat:@"stripeToken=%@", self.tokenId];

    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [body appendFormat:@"&%@=%@", key, obj];
    }];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:handler];
}

@end
