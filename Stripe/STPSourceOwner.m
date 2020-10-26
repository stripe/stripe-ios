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

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    STPSourceOwner *owner = [self new];
    owner.allResponseFields = dict;
    NSDictionary *rawAddress = [dict stp_dictionaryForKey:@"address"];
    owner.address = [STPAddress decodedObjectFromAPIResponse:rawAddress];
    owner.email = [dict stp_stringForKey:@"email"];
    owner.name = [dict stp_stringForKey:@"name"];
    owner.phone = [dict stp_stringForKey:@"phone"];
    NSDictionary *rawVerifiedAddress = [dict stp_dictionaryForKey:@"verified_address"];
    owner.verifiedAddress = [STPAddress decodedObjectFromAPIResponse:rawVerifiedAddress];
    owner.verifiedEmail = [dict stp_stringForKey:@"verified_email"];
    owner.verifiedName = [dict stp_stringForKey:@"verified_name"];
    owner.verifiedPhone = [dict stp_stringForKey:@"verified_phone"];
    return owner;
}

@end
