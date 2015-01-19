//
//  STPFormEncoder.m
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormEncoder.h"
#import "STPBankAccount.h"
#import "STPCard.h"

@implementation STPFormEncoder

+ (NSData *)formEncodedDataForBankAccount:(STPBankAccount *)bankAccount {
    NSCAssert(bankAccount != nil, @"Cannot create a token with a nil bank account.");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray *parts = [NSMutableArray array];
    
    if (bankAccount.accountNumber) {
        params[@"account_number"] = bankAccount.accountNumber;
    }
    if (bankAccount.routingNumber) {
        params[@"routing_number"] = bankAccount.routingNumber;
    }
    if (bankAccount.country) {
        params[@"country"] = bankAccount.country;
    }
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id val, __unused BOOL *stop) {
        [parts addObject:[NSString stringWithFormat:@"bank_account[%@]=%@", key, [self.class stringByURLEncoding:val]]];
    }];
    
    return [[parts componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
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

/* This code is adapted from the code by David DeLong in this StackOverflow post:
 http://stackoverflow.com/questions/3423545/objective-c-iphone-percent-encode-a-string .  It is protected under the terms of a Creative Commons
 license: http://creativecommons.org/licenses/by-sa/3.0/
 */
+ (NSString *)stringByURLEncoding:(NSString *)string {
    NSMutableString *output = [NSMutableString string];
    const unsigned char *source = (const unsigned char *)[string UTF8String];
    NSInteger sourceLen = strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' ') {
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' || (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') || (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input {
    NSArray *parts = [input componentsSeparatedByString:@"_"];
    NSMutableString *camelCaseParam = [NSMutableString string];
    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        [camelCaseParam appendString:(idx == 0 ? part : [part capitalizedString])];
    }];
    
    return [camelCaseParam copy];
}

@end
