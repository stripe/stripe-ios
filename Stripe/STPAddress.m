//
//  STPAddress.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddress.h"

#import <Contacts/Contacts.h>

#import "NSDictionary+Stripe.h"
#import "STPCardValidator.h"
#import "STPEmailAddressValidator.h"
#import "STPFormEncoder.h"
#import "STPPhoneNumberValidator.h"
#import "STPPostalCodeValidator.h"

NSString *stringIfHasContentsElseNil(NSString *string);


STPContactField const STPContactFieldPostalAddress = @"STPContactFieldPostalAddress";
STPContactField const STPContactFieldEmailAddress = @"STPContactFieldEmailAddress";
STPContactField const STPContactFieldPhoneNumber = @"STPContactFieldPhoneNumber";
STPContactField const STPContactFieldName = @"STPContactFieldName";

@interface STPAddress ()

@property (nonatomic, readwrite, nonnull, copy) NSDictionary *allResponseFields;
@property (nonatomic, readwrite, nullable, copy) NSString *givenName;
@property (nonatomic, readwrite, nullable, copy) NSString *familyName;
@end

@implementation STPAddress
@synthesize additionalAPIParameters;

+ (NSDictionary *)shippingInfoForChargeWithAddress:(nullable STPAddress *)address
                                    shippingMethod:(nullable PKShippingMethod *)method {
    if (!address) {
        return nil;
    }
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"name"] = address.name;
    params[@"phone"] = address.phone;
    params[@"carrier"] = method.label;
    // Re-use STPFormEncoder
    params[@"address"] = [STPFormEncoder dictionaryForObject:address];
    return [params copy];
}

- (NSString *)sanitizedPhoneStringFromCNPhoneNumber:(CNPhoneNumber *)phoneNumber {
    NSString *phone = phoneNumber.stringValue;
    if (phone) {
        phone = [STPCardValidator sanitizedNumericStringForString:phone];
    }

    return stringIfHasContentsElseNil(phone);
}

- (instancetype)initWithCNContact:(CNContact *)contact {
    self = [super init];
    if (self) {

        _givenName = stringIfHasContentsElseNil(contact.givenName);
        _familyName = stringIfHasContentsElseNil(contact.familyName);
        _name = stringIfHasContentsElseNil([CNContactFormatter stringFromContact:contact
                                                                           style:CNContactFormatterStyleFullName]);
        _email = stringIfHasContentsElseNil([contact.emailAddresses firstObject].value);
        _phone = [self sanitizedPhoneStringFromCNPhoneNumber:contact.phoneNumbers.firstObject.value];


        [self setAddressFromCNPostalAddress:contact.postalAddresses.firstObject.value];
    }
    return self;
}

- (instancetype)initWithPKContact:(PKContact *)contact {
    self = [super init];
    if (self) {
        NSPersonNameComponents *nameComponents = contact.name;
        if (nameComponents) {
            _givenName = stringIfHasContentsElseNil(nameComponents.givenName);
            _familyName = stringIfHasContentsElseNil(nameComponents.familyName);
            _name = stringIfHasContentsElseNil([NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:nameComponents
                                                                                                                  style:NSPersonNameComponentsFormatterStyleDefault
                                                                                                                options:(NSPersonNameComponentsFormatterOptions)0]);
        }
        _email = stringIfHasContentsElseNil(contact.emailAddress);
        _phone = [self sanitizedPhoneStringFromCNPhoneNumber:contact.phoneNumber];
        [self setAddressFromCNPostalAddress:contact.postalAddress];

    }
    return self;
}

- (void)setAddressFromCNPostalAddress:(CNPostalAddress *)address {
    if (address) {
        _line1 = stringIfHasContentsElseNil(address.street);
        _city = stringIfHasContentsElseNil(address.city);
        _state = stringIfHasContentsElseNil(address.state);
        _postalCode = stringIfHasContentsElseNil(address.postalCode);
        _country = stringIfHasContentsElseNil(address.ISOCountryCode.uppercaseString);
    }
}

- (PKContact *)PKContactValue {
    PKContact *contact = [PKContact new];
    NSPersonNameComponents *name = [NSPersonNameComponents new];
    name.givenName = [self firstName];
    name.familyName = [self lastName];
    contact.name = name;
    contact.emailAddress = self.email;
    CNMutablePostalAddress *address = [CNMutablePostalAddress new];
    address.street = [self street];
    address.city = self.city;
    address.state = self.state;
    address.postalCode = self.postalCode;
    address.country = self.country;
    contact.postalAddress = address;
    contact.phoneNumber = [CNPhoneNumber phoneNumberWithStringValue:self.phone];
    return contact;
}

- (NSString *)firstName {
    if (self.givenName) {
        return self.givenName;
    }
    else {
        NSArray<NSString *>*components = [self.name componentsSeparatedByString:@" "];
        return [components firstObject];
    }
}

- (NSString *)lastName {
    if (self.familyName) {
        return self.familyName;
    }
    else {
        NSArray<NSString *>*components = [self.name componentsSeparatedByString:@" "];
        NSString *firstName = [components firstObject];
        NSString *lastName = [self.name stringByReplacingOccurrencesOfString:firstName withString:@""];
        lastName = [lastName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([lastName length] == 0) {
            lastName = nil;
        }
        return lastName;
    }
}

- (NSString *)street {
    NSString *street = nil;
    if (self.line1 != nil) {
        street = [@"" stringByAppendingString:self.line1];
    }
    if (self.line2 != nil) {
        street = [@[street ?: @"", self.line2] componentsJoinedByString:@" "];
    }
    return street;
}

- (BOOL)containsRequiredFields:(STPBillingAddressFields)requiredFields {
    BOOL containsFields = YES;
    switch (requiredFields) {
        case STPBillingAddressFieldsNone:
            return YES;
        case STPBillingAddressFieldsZip:
            return ([STPPostalCodeValidator validationStateForPostalCode:self.postalCode
                                                             countryCode:self.country] == STPCardValidationStateValid);
        case STPBillingAddressFieldsFull:
            return [self hasValidPostalAddress];
    }
    return containsFields;
}

- (BOOL)containsContentForBillingAddressFields:(STPBillingAddressFields)desiredFields {
    switch (desiredFields) {
        case STPBillingAddressFieldsNone:
            return NO;
        case STPBillingAddressFieldsZip:
            return self.postalCode.length > 0;
        case STPBillingAddressFieldsFull:
            return [self hasPartialPostalAddress];
    }

    return NO;
}

- (BOOL)containsRequiredShippingAddressFields:(NSSet<STPContactField> *)requiredFields {
    BOOL containsFields = YES;

    if ([requiredFields containsObject:STPContactFieldName]) {
        containsFields = containsFields && [self.name length] > 0;
    }
    if ([requiredFields containsObject:STPContactFieldEmailAddress]) {
        containsFields = containsFields && [STPEmailAddressValidator stringIsValidEmailAddress:self.email];
    }
    if ([requiredFields containsObject:STPContactFieldPhoneNumber]) {
        containsFields = containsFields && [STPPhoneNumberValidator stringIsValidPhoneNumber:self.phone forCountryCode:self.country];
    }
    if ([requiredFields containsObject:STPContactFieldPostalAddress]) {
        containsFields = containsFields && [self hasValidPostalAddress];
    }
    return containsFields;
}

- (BOOL)containsContentForShippingAddressFields:(NSSet<STPContactField> *)desiredFields {
    return (([desiredFields containsObject:STPContactFieldName] && self.name.length > 0)
            || ([desiredFields containsObject:STPContactFieldEmailAddress] && self.email.length > 0)
            || ([desiredFields containsObject:STPContactFieldPhoneNumber] && self.phone.length > 0)
            || ([desiredFields containsObject:STPContactFieldPostalAddress] && [self hasPartialPostalAddress]));
}

- (BOOL)hasValidPostalAddress {
    return (self.line1.length > 0 
            && self.city.length > 0 
            && self.country.length > 0 
            && (self.state.length > 0 || ![self.country isEqualToString:@"US"])  
            && ([STPPostalCodeValidator validationStateForPostalCode:self.postalCode
                                                         countryCode:self.country] == STPCardValidationStateValid));
}

/**
 Does this STPAddress contain any data in the postal address fields?

 If they are all empty or nil, returns NO. Even a single character in a
 single field will return YES.
 */
- (BOOL)hasPartialPostalAddress {
    return (self.line1.length > 0
            || self.line2.length > 0
            || self.city.length > 0
            || self.country.length > 0
            || self.state.length > 0
            || self.postalCode.length > 0);
}

+ (PKAddressField)applePayAddressFieldsFromBillingAddressFields:(STPBillingAddressFields)billingAddressFields {
    switch (billingAddressFields) {
        case STPBillingAddressFieldsNone:
            return PKAddressFieldNone;
        case STPBillingAddressFieldsZip:
        case STPBillingAddressFieldsFull:
            return PKAddressFieldPostalAddress;
    }
}

+ (PKAddressField)pkAddressFieldsFromStripeContactFields:(NSSet<STPContactField> *)contactFields {
    PKAddressField addressFields = PKAddressFieldNone;
    NSDictionary<STPContactField, NSNumber *> *contactToAddressFieldMap
    = @{
        STPContactFieldPostalAddress: @(PKAddressFieldPostalAddress),
        STPContactFieldEmailAddress: @(PKAddressFieldEmail),
        STPContactFieldPhoneNumber: @(PKAddressFieldPhone),
        STPContactFieldName: @(PKAddressFieldName),
        };

    for (STPContactField contactField in contactFields) {
        NSNumber *boxedConvertedField = contactToAddressFieldMap[contactField];
        if (boxedConvertedField) {
            addressFields = (PKAddressField) (addressFields | [boxedConvertedField unsignedIntegerValue]);
        }
    }
    return addressFields;
}

+ (NSSet<PKContactField> *)pkContactFieldsFromStripeContactFields:(NSSet<STPContactField> *)contactFields API_AVAILABLE(ios(11.0)) {
    if (contactFields == nil) {
        return nil;
    }

    NSMutableSet<PKContactField> *pkFields = [NSMutableSet new];
    NSDictionary<STPContactField, PKContactField> *stripeToPayKitContactMap
    = @{
        STPContactFieldPostalAddress: PKContactFieldPostalAddress,
        STPContactFieldEmailAddress: PKContactFieldEmailAddress,
        STPContactFieldPhoneNumber: PKContactFieldPhoneNumber,
        STPContactFieldName: PKContactFieldName,
        };

    for (STPContactField contactField in contactFields) {
        PKContactField convertedField = stripeToPayKitContactMap[contactField];
        if (convertedField != nil) {
            [pkFields addObject:convertedField];
        }
    }
    return pkFields.copy;
}

#pragma mark STPAPIResponseDecodable

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNulls];
    if (!dict) {
        return nil;
    }

    STPAddress *address = [self new];
    address.allResponseFields = dict;
    /// all properties are nullable
    address.city = [dict stp_stringForKey:@"city"];
    address.country = [dict stp_stringForKey:@"country"];
    address.line1 = [dict stp_stringForKey:@"line1"];
    address.line2 = [dict stp_stringForKey:@"line2"];
    address.postalCode = [dict stp_stringForKey:@"postal_code"];
    address.state = [dict stp_stringForKey:@"state"];
    return address;
}

#pragma mark STPFormEncodable

+ (nullable NSString *)rootObjectName {
    return nil;
}

+ (NSDictionary *)propertyNamesToFormFieldNamesMapping {
    // Paralleling `decodedObjectFromAPIResponse:`, *only* the 6 address fields are encoded
    // If this changes, shippingInfoForChargeWithAddress:shippingMethod: might break
    return @{
             NSStringFromSelector(@selector(line1)): @"line1",
             NSStringFromSelector(@selector(line2)): @"line2",
             NSStringFromSelector(@selector(city)): @"city",
             NSStringFromSelector(@selector(state)): @"state",
             NSStringFromSelector(@selector(postalCode)): @"postal_code",
             NSStringFromSelector(@selector(country)): @"country",
             };
}

@end

#pragma mark -

NSString *stringIfHasContentsElseNil(NSString *string) {
    if (string.length > 0) {
        return string;
    }
    else {
        return nil;
    }
}

