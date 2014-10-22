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

- (id)initWithAttributeDictionary:(NSDictionary *)attributeDictionary {
    self = [super init];

    if (self) {
        _tokenId = attributeDictionary[@"id"];
        _object = attributeDictionary[@"object"];
        _livemode = [attributeDictionary[@"livemode"] boolValue];
        _created = [NSDate dateWithTimeIntervalSince1970:[attributeDictionary[@"created"] doubleValue]];
        _used = [attributeDictionary[@"used"] boolValue];
        _card = [[STPCard alloc] initWithAttributeDictionary:attributeDictionary[@"card"]];
    }

    return self;
}

- (NSString *)description {
    NSString *token = self.tokenId ? self.tokenId : @"Unknown token";
    NSString *livemode = self.livemode ? @"live mode" : @"test mode";

    return [NSString stringWithFormat:@"%@ (%@)", token, livemode];
}

- (void)postToURL:(NSURL *)url withParams:(NSMutableDictionary *)params completion:(void (^)(NSURLResponse *, NSData *, NSError *))handler {
    NSMutableString *body = [NSMutableString stringWithFormat:@"stripeToken=%@", self.tokenId];

    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { [body appendFormat:@"&%@=%@", key, obj]; }];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:handler];
}

- (BOOL)isEqual:(id)object {
    return [self isEqualToToken:object];
}

- (BOOL)isEqualToToken:(STPToken *)object {
    if (self == object) {
        return YES;
    }

    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }

    return self.livemode == object.livemode && self.used == object.used && [self.tokenId isEqualToString:object.tokenId] &&
           [self.created isEqualToDate:object.created] && [self.card isEqualToCard:object.card];
}

@end
