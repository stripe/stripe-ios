//
//  NSURLComponents+Stripe.m
//  Stripe
//
//  Created by Brian Dorfman on 1/26/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "NSURLComponents+Stripe.h"

@implementation NSURLComponents (Stripe)

- (NSDictionary<NSString *, NSString *> *)stp_queryItemsDictionary {
    NSMutableDictionary *queryItems = [NSMutableDictionary new];

    for (NSURLQueryItem *queryItem in self.queryItems) {
        queryItems[queryItem.name] = queryItem.value;
    }

    return queryItems.copy;
}

- (void)setStp_queryItemsDictionary:(NSDictionary<NSString *, NSString *> *)stp_queryItemsDictionary {
    NSMutableArray *queryItems = [NSMutableArray new];
    [stp_queryItemsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * __unused _Nonnull stop) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:obj]];
    }];

    self.queryItems = queryItems.copy;
}

- (BOOL)stp_matchesURLComponents:(NSURLComponents *)rhsComponents {
    BOOL matches = ([[self.scheme lowercaseString] isEqualToString:[rhsComponents.scheme lowercaseString]]
                    && [[self.host lowercaseString] isEqualToString:[rhsComponents.host lowercaseString]]
                    && [self.path isEqualToString:rhsComponents.path]);

    if (matches) {
        NSDictionary<NSString *, NSString *> *rhsQueryItems = rhsComponents.stp_queryItemsDictionary;

        for (NSURLQueryItem *queryItem in self.queryItems) {
            if (![rhsQueryItems[queryItem.name] isEqualToString:queryItem.value]) {
                matches = NO;
                break;
            }
        }
    }

    return matches;
}

@end

void linkNSURLComponentsCategory(void){}
