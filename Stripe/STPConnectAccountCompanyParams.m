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
                       [NSString stringWithFormat:@"address: %@", self.address ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanaAddress: %@", self.kanaAddress ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanjiAddress: %@", self.kanjiAddress ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"directorsProvided: %@", self.directorsProvided],
                       [NSString stringWithFormat:@"name: %@", self.name ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanaName: %@", self.kanaName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanjiName: %@", self.kanjiName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"ownersProvided: %@", self.ownersProvided],
                       [NSString stringWithFormat:@"phone: %@", self.phone ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"taxID: %@", self.taxID ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"taxIDRegistrar: %@", self.taxIDRegistrar ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"vatID: %@", self.vatID ? @"<redacted>" : nil],
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

