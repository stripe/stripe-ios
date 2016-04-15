//
//  STPAddress.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPAddress.h"
#import "STPCardValidator.h"

@implementation STPAddress

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

- (instancetype)initWithABRecord:(ABRecordRef)record {
    self = [super init];
    if (self) {
        NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
        NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
        NSString *first = firstName ?: @"";
        NSString *last = lastName ?: @"";
        _name = [@[first, last] componentsJoinedByString:@" "];
        ABMultiValueRef emailValues = ABRecordCopyValue(record, kABPersonEmailProperty);
        _email = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(emailValues, 0));
        ABMultiValueRef phoneValues = ABRecordCopyValue(record, kABPersonPhoneProperty);
        NSString *phone = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(phoneValues, 0));
        _phone = [STPCardValidator sanitizedNumericStringForString:phone];

        ABMultiValueRef addressValues = ABRecordCopyValue(record, kABPersonAddressProperty);
        if (addressValues != NULL) {
            if (ABMultiValueGetCount(addressValues) > 0) {
                CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
                NSString *street = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
                if (street) {
                    _line1 = street;
                }
                NSString *city = CFDictionaryGetValue(dict, kABPersonAddressCityKey);
                if (city) {
                    _city = city;
                }
                NSString *state = CFDictionaryGetValue(dict, kABPersonAddressStateKey);
                if (state) {
                    _state = state;
                }
                NSString *zip = CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
                if (zip) {
                    _postalCode = zip;
                }
                NSString *country = CFDictionaryGetValue(dict, kABPersonAddressCountryCodeKey);
                if (country) {
                    _country = country;
                }
                CFRelease(dict);
            }
            CFRelease(addressValues);
        }
    }
    return self;
}

- (BOOL)containsRequiredFields:(PKAddressField)requiredFields {
    BOOL containsFields = YES;
    if (requiredFields & PKAddressFieldPostalAddress) {
        containsFields = containsFields && [self hasValidPostalAddress];
    }
    if (requiredFields & PKAddressFieldPhone) {
        containsFields = containsFields && (self.phone != nil);
    }
    if (requiredFields & PKAddressFieldEmail) {
        containsFields = containsFields && (self.email != nil);
    }
    if (requiredFields & PKAddressFieldName) {
        containsFields = containsFields && (self.name != nil);
    }
    return containsFields;
}

- (BOOL)hasValidPostalAddress {
    return self.line1 != nil &&
    self.city != nil &&
    self.state != nil &&
    self.postalCode != nil &&
    self.country != nil;
}

#pragma clang diagnostic pop

@end

