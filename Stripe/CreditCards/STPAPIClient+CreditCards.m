//
//  STPAPIClient+CreditCards.m
//  Stripe
//
//  Created by Jack Flintermann on 12/19/14.
//  Copyright (c) 2014 Stripe, Inc. All rights reserved.
//

#import "STPAPIClient+CreditCards.h"
#import "STPCard.h"

@implementation STPAPIClient (CreditCards)

- (void)createTokenWithCard:(STPCard *)card completion:(STPCompletionBlock)completion {
    [self createTokenWithData:[self.class formEncodedDataForCard:card] completion:completion];
}

+ (NSData *)formEncodedDataForCard:(STPCard *)card {
    NSCAssert(card != nil, @"Cannot create a token with a nil card.");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];

    if (card.number) {
        params[@"number"] = card.number;
    }
    if (card.cvc) {
        params[@"cvc"] = card.cvc;
    }
    if (card.name) {
        params[@"name"] = card.name;
    }
    if (card.addressLine1) {
        params[@"address_line1"] = card.addressLine1;
    }
    if (card.addressLine2) {
        params[@"address_line2"] = card.addressLine2;
    }
    if (card.addressCity) {
        params[@"address_city"] = card.addressCity;
    }
    if (card.addressState) {
        params[@"address_state"] = card.addressState;
    }
    if (card.addressZip) {
        params[@"address_zip"] = card.addressZip;
    }
    if (card.addressCountry) {
        params[@"address_country"] = card.addressCountry;
    }
    if (card.expMonth) {
        params[@"exp_month"] = @(card.expMonth).stringValue;
    }
    if (card.expYear) {
        params[@"exp_year"] = @(card.expYear).stringValue;
    }

    NSMutableArray *parts = [NSMutableArray array];

    [params enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"card[%@]=%@", key, [self.class stringByURLEncoding:val]]];

    }];

    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
