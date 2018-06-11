//
//  STPAddressViewModelTest.m
//  Stripe
//
//  Created by Ben Guo on 10/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "STPAddressViewModel.h"

@interface STPAddressViewModelTest : XCTestCase

@end

@implementation STPAddressViewModelTest

- (void)testInitWithRequiredBillingFields {
    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsNone];
    XCTAssertTrue([sut.addressCells count] == 0);
    XCTAssertTrue(sut.isValid);

    sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsZip];
    XCTAssertTrue([sut.addressCells count] == 1);
    STPAddressFieldTableViewCell *cell1 = sut.addressCells[0];
    XCTAssertEqual(cell1.type, STPAddressFieldTypeZip);

    sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsFull];
    XCTAssertTrue([sut.addressCells count] == 7);
    NSArray *types = @[
                       @(STPAddressFieldTypeName),
                       @(STPAddressFieldTypeLine1),
                       @(STPAddressFieldTypeLine2),
                       @(STPAddressFieldTypeZip),
                       @(STPAddressFieldTypeCity),
                       @(STPAddressFieldTypeState),
                       @(STPAddressFieldTypeCountry),
                       ];
    for (NSUInteger i=0; i<[sut.addressCells count]; i++) {
        XCTAssertEqual(sut.addressCells[i].type, [types[i] integerValue]);
    }

    sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsName];
    XCTAssertTrue([sut.addressCells count] == 1);
    XCTAssertEqual(sut.addressCells[0].type, STPAddressFieldTypeName);
}

- (void)testInitWithRequiredShippingFields {
    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredShippingFields:nil];
    XCTAssertTrue([sut.addressCells count] == 0);

    sut = [[STPAddressViewModel alloc] initWithRequiredShippingFields:[NSSet setWithArray:@[STPContactFieldName]]];
    XCTAssertTrue([sut.addressCells count] == 1);
    STPAddressFieldTableViewCell *cell1 = sut.addressCells[0];
    XCTAssertEqual(cell1.type, STPAddressFieldTypeName);

    sut = [[STPAddressViewModel alloc] initWithRequiredShippingFields:[NSSet setWithArray:@[STPContactFieldName, STPContactFieldEmailAddress]]];
    XCTAssertTrue([sut.addressCells count] == 2);
    NSArray *types = @[
                       @(STPAddressFieldTypeName),
                       @(STPAddressFieldTypeEmail),
                       ];
    for (NSUInteger i=0; i<[sut.addressCells count]; i++) {
        XCTAssertEqual(sut.addressCells[i].type, [types[i] integerValue]);
    }

    sut = [[STPAddressViewModel alloc] initWithRequiredShippingFields:[NSSet setWithArray:@[STPContactFieldPostalAddress, STPContactFieldEmailAddress, STPContactFieldPhoneNumber]]];
    XCTAssertTrue([sut.addressCells count] == 9);
    types = @[
              @(STPAddressFieldTypeEmail),
              @(STPAddressFieldTypeName),
              @(STPAddressFieldTypeLine1),
              @(STPAddressFieldTypeLine2),
              @(STPAddressFieldTypeZip),
              @(STPAddressFieldTypeCity),
              @(STPAddressFieldTypeState),
              @(STPAddressFieldTypeCountry),
              @(STPAddressFieldTypePhone),
              ];
    for (NSUInteger i=0; i<[sut.addressCells count]; i++) {
        XCTAssertEqual(sut.addressCells[i].type, [types[i] integerValue]);
    }
}

- (void)testGetAddress {
    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredShippingFields:[NSSet setWithArray:@[STPContactFieldPostalAddress, STPContactFieldEmailAddress, STPContactFieldPhoneNumber]]];
    sut.addressCells[0].contents = @"foo@example.com";
    sut.addressCells[1].contents = @"John Smith";
    sut.addressCells[2].contents = @"55 John St";
    sut.addressCells[3].contents = @"#3B";
    sut.addressCells[4].contents = @"10002";
    sut.addressCells[5].contents = @"New York";
    sut.addressCells[6].contents = @"NY";
    sut.addressCells[7].contents = @"US";
    sut.addressCells[8].contents = @"555-555-5555";

    XCTAssertEqualObjects(sut.address.email, @"foo@example.com");
    XCTAssertEqualObjects(sut.address.name, @"John Smith");
    XCTAssertEqualObjects(sut.address.line1, @"55 John St");
    XCTAssertEqualObjects(sut.address.line2, @"#3B");
    XCTAssertEqualObjects(sut.address.city, @"New York");
    XCTAssertEqualObjects(sut.address.state, @"NY");
    XCTAssertEqualObjects(sut.address.postalCode, @"10002");
    XCTAssertEqualObjects(sut.address.country, @"US");
    XCTAssertEqualObjects(sut.address.phone, @"555-555-5555");
}

- (void)testSetAddress {
    STPAddress *address = [STPAddress new];
    address.email = @"foo@example.com";
    address.name = @"John Smith";
    address.line1 = @"55 John St";
    address.line2 = @"#3B";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";
    address.phone = @"555-555-5555";

    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredShippingFields:[NSSet setWithArray:@[STPContactFieldPostalAddress, STPContactFieldEmailAddress, STPContactFieldPhoneNumber]]];
    sut.address = address;
    XCTAssertEqualObjects(sut.addressCells[0].contents, @"foo@example.com");
    XCTAssertEqualObjects(sut.addressCells[1].contents, @"John Smith");
    XCTAssertEqualObjects(sut.addressCells[2].contents, @"55 John St");
    XCTAssertEqualObjects(sut.addressCells[3].contents, @"#3B");
    XCTAssertEqualObjects(sut.addressCells[4].contents, @"10002");
    XCTAssertEqualObjects(sut.addressCells[5].contents, @"New York");
    XCTAssertEqualObjects(sut.addressCells[6].contents, @"NY");
    XCTAssertEqualObjects(sut.addressCells[7].contents, @"US");
    XCTAssertEqualObjects(sut.addressCells[7].textField.text, @"United States");
    XCTAssertEqualObjects(sut.addressCells[8].contents, @"555-555-5555");
}

- (void)testIsValid_Zip {
    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsZip];

    STPAddress *address = [STPAddress new];

    address.country = @"US";
    sut.address = address;
    XCTAssertEqual(sut.addressCells.count, 1ul);
    XCTAssertFalse(sut.isValid, @"US addresses have postalCode, require it when requiredBillingFields is .Zip");

    address.postalCode = @"94016";
    sut.address = address;
    XCTAssertTrue(sut.isValid);

    address.country = @"MO"; // in Macao, postalCode is optional
    address.postalCode = nil;
    sut.address = address;
    XCTAssertEqual(sut.addressCells.count, 0ul);
    XCTAssertTrue(sut.isValid, @"in Macao, postalCode is optional, valid without one");
}


- (void)testIsValid_Full {
    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsFull];
    XCTAssertFalse(sut.isValid);
    sut.addressCells[0].contents = @"John Smith";
    sut.addressCells[1].contents = @"55 John St";
    sut.addressCells[2].contents = @"#3B";
    XCTAssertFalse(sut.isValid);
    sut.addressCells[3].contents = @"10002";
    sut.addressCells[4].contents = @"New York";
    sut.addressCells[5].contents = @"NY";
    sut.addressCells[6].contents = @"US";
    XCTAssertTrue(sut.isValid);
}

- (void)testIsValid_Name {
    STPAddressViewModel *sut = [[STPAddressViewModel alloc] initWithRequiredBillingFields:STPBillingAddressFieldsName];

    STPAddress *address = [STPAddress new];

    address.name = @"";
    sut.address = address;
    XCTAssertEqual(sut.addressCells.count, 1ul);
    XCTAssertFalse(sut.isValid);

    address.name = @"Jane Doe";
    sut.address = address;
    XCTAssertEqual(sut.addressCells.count, 1ul);
    XCTAssertTrue(sut.isValid);
}

@end
