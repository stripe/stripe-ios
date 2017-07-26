//
//  STPSourceOwner.m
//  Stripe
//
//  Created by Ben Guo on 1/25/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPSourceOwner.h"

#import "NSDictionary+Stripe.h"
#import "STPAddress.h"

@interface STPSourceOwner ()

@property (nonatomic, nullable) STPAddress *address;
@property (nonatomic, nullable) NSString *email;
@property (nonatomic, nullable) NSString *name;
@property (nonatomic, nullable) NSString *phone;
@property (nonatomic, nullable) STPAddress *verifiedAddress;
@property (nonatomic, nullable) NSString *verifiedEmail;
@property (nonatomic, nullable) NSString *verifiedName;
@property (nonatomic, nullable) NSString *verifiedPhone;
@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;

@end

@implementation STPSourceOwner

#pragma mark - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[];
}

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }

    STPSourceOwner *owner = [self new];
    owner.allResponseFields = dict;
    owner.address = [STPAddress decodedObjectFromAPIResponse:dict[@"address"]];
    owner.email = dict[@"email"];
    owner.name = dict[@"name"];
    owner.phone = dict[@"phone"];
    owner.verifiedAddress = [STPAddress decodedObjectFromAPIResponse:dict[@"verified_address"]];
    owner.verifiedEmail = dict[@"verified_email"];
    owner.verifiedName = dict[@"verified_name"];
    owner.verifiedPhone = dict[@"verified_phone"];
    return owner;
}

@end
