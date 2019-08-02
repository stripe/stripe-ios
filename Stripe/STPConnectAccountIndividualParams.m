//
//  STPConnectAccountIndividualParams.m
//  Stripe
//
//  Created by Yuki Tokuhiro on 8/2/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPConnectAccountIndividualParams.h"

@implementation STPConnectAccountIndividualParams

- (NSString *)description {
    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       
                       // Properties
                       // Not including most properties since they are PII
                       [NSString stringWithFormat:@"verification = %@", self.verification],
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
             NSStringFromSelector(@selector(dateOfBirth)): @"dob",
             NSStringFromSelector(@selector(email)): @"email",
             NSStringFromSelector(@selector(firstName)): @"first_name",
             NSStringFromSelector(@selector(kanaFirstName)): @"first_name_kana",
             NSStringFromSelector(@selector(kanjiFirstName)): @"first_name_kanji",
             NSStringFromSelector(@selector(gender)): @"gender",
             NSStringFromSelector(@selector(idNumber)): @"id_number",
             NSStringFromSelector(@selector(lastName)): @"last_name",
             NSStringFromSelector(@selector(kanaLastName)): @"last_name_kana",
             NSStringFromSelector(@selector(kanjiLastName)): @"last_name_kanji",
             NSStringFromSelector(@selector(maidenName)): @"maiden_name",
             NSStringFromSelector(@selector(metadata)): @"metadata",
             NSStringFromSelector(@selector(phone)): @"phone",
             NSStringFromSelector(@selector(ssnLast4)): @"ssn_last_4",
             NSStringFromSelector(@selector(verification)): @"verification",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end

#pragma mark -

@implementation STPConnectAccountIndividualVerification
@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(document)): @"document",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end

#pragma mark -

@implementation STPConnectAccountVerificationDocument
@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(back)): @"back",
             NSStringFromSelector(@selector(front)): @"front",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end
