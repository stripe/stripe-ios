//
//  STPLegalEntityParams.m
//  Stripe
//
//  Created by Daniel Jackson on 12/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPLegalEntityParams.h"
#import "FauxPasAnnotations.h"

NS_ASSUME_NONNULL_BEGIN

@implementation STPVerificationParams
@synthesize additionalAPIParameters;

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       [NSString stringWithFormat:@"document = %@", self.document],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable NSString *)rootObjectName {
    return @"verification";
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(document)): @"document",
             };
}

@end

@implementation STPPersonParams
@synthesize additionalAPIParameters;

- (NSString *)description {
    NSArray *props = @[
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],

                       [NSString stringWithFormat:@"firstName = %@", self.firstName],
                       [NSString stringWithFormat:@"lastName = %@", self.lastName],
                       [NSString stringWithFormat:@"maidenName = %@", self.maidenName],
                       [NSString stringWithFormat:@"address = <%@>", self.address],
                       [NSString stringWithFormat:@"dateOfBirth = <%@>", self.dateOfBirth],
                       [NSString stringWithFormat:@"verification = %@", self.verification],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable NSString *)rootObjectName {
    // STPPersonParams is never a named root object. It's either inherited by STPLegalEntityParams
    // or an element in the STPLegalEntityParams.additionalOwners array
    return nil;
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    return @{
             NSStringFromSelector(@selector(firstName)): @"first_name",
             NSStringFromSelector(@selector(lastName)): @"last_name",
             NSStringFromSelector(@selector(maidenName)): @"maiden_name",
             NSStringFromSelector(@selector(address)): @"address",
             NSStringFromSelector(@selector(dateOfBirth)): @"dob",
             NSStringFromSelector(@selector(verification)): @"verification",
             };
}

@end

@implementation STPLegalEntityParams

- (NSString *)description {

    NSArray *props = @[
                       // Object
                       [NSString stringWithFormat:@"%@: %p", NSStringFromClass([self class]), self],
                       [NSString stringWithFormat:@"super = %@", [super description]],

                       [NSString stringWithFormat:@"additionalOwners = %@", self.additionalOwners],
                       [NSString stringWithFormat:@"businessName = %@", self.businessName],
                       [NSString stringWithFormat:@"businessTaxId = %@", self.businessTaxId],
                       [NSString stringWithFormat:@"businessVATId = %@", self.businessVATId],
                       [NSString stringWithFormat:@"genderString = %@", self.genderString],
                       [NSString stringWithFormat:@"personalAddress = %@", self.personalAddress],
                       [NSString stringWithFormat:@"personalIdNumber = %@", self.personalIdNumber],
                       [NSString stringWithFormat:@"phoneNumber = %@", self.phoneNumber],
                       [NSString stringWithFormat:@"ssnLast4 = %@", self.ssnLast4],
                       [NSString stringWithFormat:@"taxIdRegistrar = %@", self.taxIdRegistrar],
                       [NSString stringWithFormat:@"entityTypeString = %@", self.entityTypeString],
                       ];

    return [NSString stringWithFormat:@"<%@>", [props componentsJoinedByString:@"; "]];
}

+ (nullable NSString *)rootObjectName {
    return @"legal_entity";
}

+ (nonnull NSDictionary *)propertyNamesToFormFieldNamesMapping {
    NSMutableDictionary *props = [@{
                                    NSStringFromSelector(@selector(additionalOwners)): @"additional_owners",
                                    NSStringFromSelector(@selector(businessName)): @"business_name",
                                    NSStringFromSelector(@selector(businessTaxId)): @"business_tax_id",
                                    NSStringFromSelector(@selector(businessVATId)): @"business_vat_id",
                                    NSStringFromSelector(@selector(genderString)): @"gender",
                                    NSStringFromSelector(@selector(personalAddress)): @"personal_address",
                                    NSStringFromSelector(@selector(personalIdNumber)): @"personal_id_number",
                                    NSStringFromSelector(@selector(phoneNumber)): @"phone_number",
                                    NSStringFromSelector(@selector(ssnLast4)): @"ssn_last_4",
                                    NSStringFromSelector(@selector(taxIdRegistrar)): @"tax_id_registrar",
                                    NSStringFromSelector(@selector(entityTypeString)): @"type",
                                    } mutableCopy];

    [props addEntriesFromDictionary:[super propertyNamesToFormFieldNamesMapping]];

    return [props copy];
}

@end


/*
 Add STPFormEncodable conformance for `STPPersonParams.dateOfBirth`.

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
