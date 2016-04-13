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
    ABRecordSetValue(record, kABPersonPhoneProperty, CFSTR("555-555-5555"), nil);
    ABRecordSetValue(record, kABPersonEmailProperty, CFSTR("foo@example.com"), nil);
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
    XCTAssertEqualObjects(@"555-555-5555", address.phone);
    XCTAssertEqualObjects(@"foo@example.com", address.email);
    XCTAssertEqualObjects(@"55 John St", address.street);
    XCTAssertEqualObjects(@"New York", address.city);
    XCTAssertEqualObjects(@"NY", address.state);
    XCTAssertEqualObjects(@"10002", address.postalCode);
    XCTAssertEqualObjects(@"US", address.country);
}

@end
