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
                                  (NSString *)kABPersonAddressCountryCodeKey: @"US",
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

@end
