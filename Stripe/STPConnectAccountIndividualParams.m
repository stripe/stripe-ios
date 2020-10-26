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
                       [NSString stringWithFormat:@"address = %@", self.address ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanaAddress = %@", self.kanaAddress ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanjiAddress = %@", self.kanjiAddress ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"dateOfBirth = %@", self.dateOfBirth ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"email = %@", self.email ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"firstName = %@", self.firstName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanaFirstName = %@", self.kanaFirstName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanjiFirstName = %@", self.kanjiFirstName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"gender = %@", self.gender ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"idNumber = %@", self.idNumber ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"lastName = %@", self.lastName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanaLastName = %@", self.kanaLastName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"kanjiLastNaame = %@", self.kanjiLastName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"maidenName = %@", self.maidenName ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"metadata = %@", self.metadata ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"phone = %@", self.phone ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"ssnLast4 = %@", self.ssnLast4 ? @"<redacted>" : nil],
                       [NSString stringWithFormat:@"verification = %@", self.verification],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

#pragma mark - STPFormEncodable

@synthesize additionalAPIParameters;

- (STPDateOfBirth *)_dateOfBirth {
    if (!self.dateOfBirth) {
        return nil;
    }

    STPDateOfBirth *dob = [STPDateOfBirth new];
    dob.day = self.dateOfBirth.day;
    dob.month = self.dateOfBirth.month;
    dob.year = self.dateOfBirth.year;
    return dob;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(address)): @"address",
             NSStringFromSelector(@selector(kanaAddress)): @"address_kana",
             NSStringFromSelector(@selector(kanjiAddress)): @"address_kanji",
             NSStringFromSelector(@selector(_dateOfBirth)): @"dob",
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

#pragma mark -

@implementation STPDateOfBirth
@synthesize additionalAPIParameters;

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(day)): @"day",
             NSStringFromSelector(@selector(month)): @"month",
             NSStringFromSelector(@selector(year)): @"year",
             };
}

+ (nullable NSString *)rootObjectName {
    return nil;
}

@end
