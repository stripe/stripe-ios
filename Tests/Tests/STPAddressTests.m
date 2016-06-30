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

- (void)testContainsRequiredFields {
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

    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.country = nil;
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsFull]);
    XCTAssertTrue([address containsRequiredFields:STPBillingAddressFieldsZip]);
    address.postalCode = nil;
    XCTAssertFalse([address containsRequiredFields:STPBillingAddressFieldsZip]);
}

@end
