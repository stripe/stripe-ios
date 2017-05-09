//
//  STPDropInConfiguration.m
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPDropInConfiguration.h"
#import "NSDictionary+Stripe.h"

@interface STPDropInConfiguration ()

@property (nonatomic, readwrite) NSString *publishableKey;
@property (nonatomic, readwrite) NSString *customerID;
@property (nonatomic, readwrite) NSString *customerResourceKey;
@property (nonatomic, readwrite) NSDate *customerResourceKeyExpirationDate;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPDropInConfiguration

+ (NSArray *)requiredFields {
    return @[@"contents", @"expires"];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    STPDropInConfiguration *config = [self new];
    config.publishableKey = dict[@"publishable_key"];
    config.customerID = dict[@"customer_id"];
    config.customerResourceKey = dict[@"resource_key"];
    config.customerResourceKeyExpirationDate = [NSDate dateWithTimeIntervalSince1970:[dict[@"expires"] doubleValue]];
    config.allResponseFields = dict;
    return config;
}

@end
