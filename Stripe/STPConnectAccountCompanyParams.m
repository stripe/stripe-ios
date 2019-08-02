//
//  STPConnectAccountCompanyParams.m
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPConnectAccountCompanyParams.h"

@implementation STPConnectAccountCompanyParams

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties omitted b/c they're PII
                       ];
    
    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(address)): @"address",
             NSStringFromSelector(@selector(kanaAddress)): @"address_kana",
             NSStringFromSelector(@selector(kanjiAddress)): @"address_kanji",
             NSStringFromSelector(@selector(directorsProvided)): @"directorsProvided",
             NSStringFromSelector(@selector(name)): @"name",
             NSStringFromSelector(@selector(kanaName)): @"name_kana",
             NSStringFromSelector(@selector(kanjiName)): @"name_kanji",
             NSStringFromSelector(@selector(ownersProvided)): @"owners_provided",
             NSStringFromSelector(@selector(phone)): @"phone",
             NSStringFromSelector(@selector(taxID)): @"tax_id",
             NSStringFromSelector(@selector(taxIDRegistrar)): @"tax_id_registrar",
             NSStringFromSelector(@selector(vatID)): @"vat_id",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end

