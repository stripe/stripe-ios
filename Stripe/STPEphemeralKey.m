//
//  STPEphemeralKey.m
//  Stripe
//
//  Created by Ben Guo on 5/4/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPEphemeralKey.h"

#import "NSDictionary+Stripe.h"

@interface STPEphemeralKey ()

@property (nonatomic, readwrite) NSString *stripeID;
@property (nonatomic, readwrite) NSDate *created;
@property (nonatomic, readwrite) BOOL livemode;
@property (nonatomic, readwrite) NSString *secret;
@property (nonatomic, readwrite) NSDate *expires;
@property (nonatomic, readwrite) NSString *customerID;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPEphemeralKey

+ (NSArray *)requiredFields {
    return @[@"id", @"created", @"livemode", @"secret", @"expires", @"associated_objects"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    NSArray<NSDictionary *>*associatedObjects = dict[@"associated_objects"];
    NSString *customerID;
    for (NSDictionary *obj in associatedObjects) {
        NSString *type = obj[@"type"];
        if ([type isEqualToString:@"customer"]) {
            customerID = obj[@"id"];
        }
    }
    if (!customerID) {
        return nil;
    }
    STPEphemeralKey *key = [self new];
    key.customerID = customerID;
    key.stripeID = dict[@"id"];
    key.livemode = [dict[@"livemode"] boolValue];
    key.created = [NSDate dateWithTimeIntervalSince1970:[dict[@"created"] doubleValue]];
    key.secret = dict[@"secret"];
    key.expires = [NSDate dateWithTimeIntervalSince1970:[dict[@"expires"] doubleValue]];
    key.allResponseFields = dict;
    return key;
}

- (NSUInteger)hash {
    return [self.stripeID hash];
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (!object || ![object isKindOfClass:self.class]) {
        return NO;
    }
    return [self isEqualToResourceKey:object];
}

- (BOOL)isEqualToResourceKey:(STPEphemeralKey *)other {
    return [self.stripeID isEqualToString:other.stripeID] 
        && [self.secret isEqualToString:other.secret]
        && [self.expires isEqual:other.expires]
        && [self.customerID isEqual:other.customerID];
}

@end
