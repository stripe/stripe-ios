//
//  STPIndividualParams.m
//  Stripe
//
//  Created by Peter Suwra on 04/27/17.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import "STPIndividualParams.h"
#import "FauxPasAnnotations.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPIndividualVerificationParams
@synthesize additionalAPIParameters;

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       [NSString stringWithFormat:@"document = %@", self.document],
                       [NSString stringWithFormat:@"documentBack = %@", self.documentBack],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable NSString *)rootObjectName {
    return @"verification";
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(document)): @"document",
             NSStringFromSelector(@selector(documentBack)): @"document_back",
             };
}

@end

@implementation STPIndividualParams
@synthesize additionalAPIParameters;

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       [NSString stringWithFormat:@"address = <%@>", self.address],
                       [NSString stringWithFormat:@"dateOfBirth = <%@>", self.dateOfBirth],
                       [NSString stringWithFormat:@"firstName = %@", self.firstName],
                       [NSString stringWithFormat:@"lastName = %@", self.lastName],
                       [NSString stringWithFormat:@"gender = %@", self.gender],
                       [NSString stringWithFormat:@"ssnLast4 = %@", self.ssnLast4],
                       [NSString stringWithFormat:@"phone = %@", self.phone],
                       [NSString stringWithFormat:@"idNumber = %@", self.idNumber],
                       [NSString stringWithFormat:@"verification = %@", self.verification],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable NSString *)rootObjectName {
    return @"individual";
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(address)): @"address",
             NSStringFromSelector(@selector(dateOfBirth)): @"dob",
             NSStringFromSelector(@selector(firstName)): @"first_name",
             NSStringFromSelector(@selector(lastName)): @"last_name",
             NSStringFromSelector(@selector(gender)): @"gender",
             NSStringFromSelector(@selector(ssnLast4)): @"ssn_last_4",
             NSStringFromSelector(@selector(phone)): @"phone",
             NSStringFromSelector(@selector(idNumber)): @"id_number",
             NSStringFromSelector(@selector(verification)): @"verification",
             };
}

@end

/*
 Add STPFormEncodable conformance for `STPIndividualParams.dateOfBirth`.

 Faux Pas (correctly) points out this is dangerous. Probably a better thing to do
 is either prefix all of these methods in the protocol, or add custom support for
 `NSDateComponents` in `+[STPFormEncoder formEncodableValueForObject:]`.

 For now, I think this is safe enough.
 */
@interface NSDateComponents (STPFormEncodable) <STPFormEncodable> @end
@implementation NSDateComponents (STPFormEncodable)

- (NSDictionary *)additionalAPIParameters {
    FAUXPAS_IGNORED_IN_METHOD(UnprefixedCategoryMethod)
    return @{};
}

- (void)setAdditionalAPIParameters:(__unused NSDictionary *)additionalAPIParameters {
    FAUXPAS_IGNORED_IN_METHOD(UnprefixedCategoryMethod)
    [self doesNotRecognizeSelector:_cmd];
}

+ (nullable NSString *)rootObjectName {
    FAUXPAS_IGNORED_IN_METHOD(UnprefixedCategoryMethod)
    return nil;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    FAUXPAS_IGNORED_IN_METHOD(UnprefixedCategoryMethod)
    return @{
             NSStringFromSelector(@selector(day)): @"day",
             NSStringFromSelector(@selector(month)): @"month",
             NSStringFromSelector(@selector(year)): @"year",
             };
}

@end

NS_ASSUME_NONNULL_END
