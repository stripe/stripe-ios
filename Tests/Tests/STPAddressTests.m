//
//  STPAddressTests.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AddressBook/AddressBook.h>
#import "STPAddress.h"

@interface STPAddressTests : XCTestCase

@end

@implementation STPAddressTests

- (void)testInit {
    ABRecordRef record = ABPersonCreate();
    ABRecordSetValue(record, kABPersonFirstNameProperty, CFSTR("John"), nil);
    ABRecordSetValue(record, kABPersonLastNameProperty, CFSTR("Doe"), nil);
    ABMutableMultiValueRef phonesRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(phonesRef, @"888-555-1212", kABPersonPhoneMainLabel, NULL);
    ABMultiValueAddValueAndLabel(phonesRef, @"555-555-5555", kABPersonPhoneMobileLabel, NULL);
    ABRecordSetValue(record, kABPersonPhoneProperty, phonesRef, nil);
    ABMutableMultiValueRef emailsRef = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    ABMultiValueAddValueAndLabel(emailsRef, @"foo@example.com", kABHomeLabel, NULL);
    ABMultiValueAddValueAndLabel(emailsRef, @"bar@example.com", kABWorkLabel, NULL);
    ABRecordSetValue(record, kABPersonEmailProperty, emailsRef, nil);
    ABMutableMultiValueRef addressRef = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    NSDictionary *addressDict = @{
                                  (NSString *)kABPersonAddressStreetKey: @"55 John St",
                                  (NSString *)kABPersonAddressCityKey: @"New York",
                                  (NSString *)kABPersonAddressStateKey: @"NY",
                                  (NSString *)kABPersonAddressZIPKey: @"10002",
                                  (NSString *)kABPersonAddressCountryCodeKey: @"us",
                                  };
    ABMultiValueAddValueAndLabel(addressRef, (__bridge CFTypeRef)(addressDict), kABWorkLabel, NULL);
    ABRecordSetValue(record, kABPersonAddressProperty, addressRef, nil);

    STPAddress *address = [[STPAddress alloc] initWithABRecord:record];
    XCTAssertEqualObjects(@"John Doe", address.name);
    XCTAssertEqualObjects(@"8885551212", address.phone);
    XCTAssertEqualObjects(@"foo@example.com", address.email);
    XCTAssertEqualObjects(@"55 John St", address.line1);
    XCTAssertEqualObjects(@"New York", address.city);
    XCTAssertEqualObjects(@"NY", address.state);
    XCTAssertEqualObjects(@"10002", address.postalCode);
    XCTAssertEqualObjects(@"US", address.country);
}

- (void)testInit_partial {
    ABRecordRef record = ABPersonCreate();
    ABRecordSetValue(record, kABPersonFirstNameProperty, CFSTR("John"), nil);
    ABMutableMultiValueRef addressRef = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    NSDictionary *addressDict = @{
                                  (NSString *)kABPersonAddressStateKey: @"VA",
                                  };
    ABMultiValueAddValueAndLabel(addressRef, (__bridge CFTypeRef)(addressDict), kABWorkLabel, NULL);
    ABRecordSetValue(record, kABPersonAddressProperty, addressRef, nil);

    STPAddress *address = [[STPAddress alloc] initWithABRecord:record];
    XCTAssertEqualObjects(@"John", address.name);
    XCTAssertNil(address.phone);
    XCTAssertNil(address.email);
    XCTAssertNil(address.line1);
    XCTAssertNil(address.city);
    XCTAssertEqualObjects(@"VA", address.state);
    XCTAssertNil(address.postalCode);
    XCTAssertNil(address.country);
}

- (void)testABRecordValue_complete {
    STPAddress *address = [STPAddress new];
    address.name = @"John Smith Doe";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";

    ABRecordRef record = [address ABRecordValue];
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    ABMultiValueRef emailValues = ABRecordCopyValue(record, kABPersonEmailProperty);
    NSString *email = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(emailValues, 0));
    CFRelease(emailValues);
    ABMultiValueRef phoneValues = ABRecordCopyValue(record, kABPersonPhoneProperty);
    NSString *phone = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(phoneValues, 0));
    CFRelease(phoneValues);
    NSString *line1, *city, *state, *postalCode, *country;
    ABMultiValueRef addressValues = ABRecordCopyValue(record, kABPersonAddressProperty);
    if (addressValues != NULL) {
        if (ABMultiValueGetCount(addressValues) > 0) {
            CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
            line1 = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
            city = CFDictionaryGetValue(dict, kABPersonAddressCityKey);
            state = CFDictionaryGetValue(dict, kABPersonAddressStateKey);
            postalCode = CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
            country = CFDictionaryGetValue(dict, kABPersonAddressCountryCodeKey);
            CFRelease(dict);
        }
        CFRelease(addressValues);
    }
    XCTAssertEqualObjects(firstName, @"John");
    XCTAssertEqualObjects(lastName, @"Smith Doe");
    XCTAssertEqualObjects(email, @"foo@example.com");
    XCTAssertEqualObjects(phone, @"8885551212");
    XCTAssertEqualObjects(line1, @"55 John St");
    XCTAssertEqualObjects(city, @"New York");
    XCTAssertEqualObjects(state, @"NY");
    XCTAssertEqualObjects(country, @"US");
    XCTAssertEqualObjects(postalCode, @"10002");
}

- (void)testABRecordValue_partial {
    STPAddress *address = [STPAddress new];
    address.name = @"John";
    address.state = @"VA";

    ABRecordRef record = [address ABRecordValue];
    NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonFirstNameProperty);
    NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(record, kABPersonLastNameProperty);
    ABMultiValueRef emailValues = ABRecordCopyValue(record, kABPersonEmailProperty);
    NSString *email = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(emailValues, 0));
    if (emailValues != NULL) {
        CFRelease(emailValues);
    }
    ABMultiValueRef phoneValues = ABRecordCopyValue(record, kABPersonPhoneProperty);
    NSString *phone = (__bridge_transfer NSString *)(ABMultiValueCopyValueAtIndex(phoneValues, 0));
    if (phoneValues != NULL) {
        CFRelease(phoneValues);
    }
    NSString *line1, *city, *state, *postalCode, *country;
    ABMultiValueRef addressValues = ABRecordCopyValue(record, kABPersonAddressProperty);
    if (addressValues != NULL) {
        if (ABMultiValueGetCount(addressValues) > 0) {
            CFDictionaryRef dict = ABMultiValueCopyValueAtIndex(addressValues, 0);
            line1 = CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
            city = CFDictionaryGetValue(dict, kABPersonAddressCityKey);
            state = CFDictionaryGetValue(dict, kABPersonAddressStateKey);
            postalCode = CFDictionaryGetValue(dict, kABPersonAddressZIPKey);
            country = CFDictionaryGetValue(dict, kABPersonAddressCountryCodeKey);
            if (dict != NULL) {
                CFRelease(dict);
            }
        }
        CFRelease(addressValues);
    }
    XCTAssertEqualObjects(firstName, @"John");
    XCTAssertNil(lastName);
    XCTAssertNil(email);
    XCTAssertNil(phone);
    XCTAssertNil(line1);
    XCTAssertNil(city);
    XCTAssertEqualObjects(state, @"VA");
    XCTAssertNil(country);
    XCTAssertNil(postalCode);
}

- (void)testContainsRequiredFieldsNone {
    STPAddress *address = [STPAddress new];
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsNone]);
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.name = @"John Doe";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsNone]);
    address.country = @"UK";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsNone]);
}


- (void)testContainsRequiredFieldsZip {
    STPAddress *address = [STPAddress new];

    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = @"IE"; //should pass for country which doesnt require zip/postal
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = @"US";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.postalCode = @"10002";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.postalCode = @"ABCDE";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = @"UK"; // should pass for alphanumeric countries
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = nil; // nil treated as alphanumeric
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
}
- (void)testContainsRequiredFieldsFull {
    STPAddress *address = [STPAddress new];
    
    /**
     *  Required fields for full are:
     *  line1, city, country, state (US only) and a valid postal code (based on country)
     */
    
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.country = @"US";
    address.line1 = @"55 John St";
    
    // Fail on partial 
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    
    address.city = @"New York";
    
    // For US fail if missing state or zip
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.state = @"NY";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.postalCode = @"ABCDE";
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    //postal must be numeric for US
    address.postalCode = @"10002";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.name = @"John Doe";
    // Name/phone/email should have no effect
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    
    // Non US countries don't require state
    address.country = @"UK";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.state = nil;
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    // alphanumeric postal ok in some countries
    address.postalCode = @"ABCDE";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    // UK requires ZIP
    address.postalCode = nil;
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    
    
    address.country = @"IE"; // Doesn't require postal or state, but allows them
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.postalCode = @"ABCDE";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
    address.state = @"Test";
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsFull]);
}

- (void)testContainsRequiredShippingAddressFields {
    STPAddress *address = [STPAddress new];
    XCTAssertTrue([address containsRequiredShippingAddressFields:PKAddressFieldNone]);
    XCTAssertFalse([address containsRequiredShippingAddressFields:PKAddressFieldAll]);

    address.name = @"John Smith";
    XCTAssertTrue([address containsRequiredShippingAddressFields:PKAddressFieldName]);
    XCTAssertFalse([address containsRequiredShippingAddressFields:PKAddressFieldEmail]);

    address.email = @"john@example.com";
    XCTAssertTrue([address containsRequiredShippingAddressFields:PKAddressFieldEmail|PKAddressFieldName]);
    XCTAssertFalse([address containsRequiredShippingAddressFields:PKAddressFieldAll]);

    address.phone = @"5555555555";
    XCTAssertTrue([address containsRequiredShippingAddressFields:PKAddressFieldEmail|PKAddressFieldName|PKAddressFieldPhone]);
    XCTAssertFalse([address containsRequiredShippingAddressFields:PKAddressFieldAll]);

    address.country = @"US";
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"12345";
    XCTAssertTrue([address containsRequiredShippingAddressFields:PKAddressFieldAll]);
}

@end
