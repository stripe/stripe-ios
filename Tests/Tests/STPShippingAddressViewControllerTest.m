//
//  STPShippingAddressViewControllerTest.m
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 8/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <Stripe/Stripe.h>
#import "NSLocale+STPSwizzling.h"
#import "STPFixtures.h"
#import "STPPostalCodeValidator.h"

@interface STPShippingAddressViewControllerTest : XCTestCase

@end

@implementation STPShippingAddressViewControllerTest

- (void)testPrefilledBillingAddress_removeAddress {
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.requiredShippingAddressFields = [NSSet setWithObject:STPContactFieldPostalAddress];

    STPAddress *address = [STPAddress new];
    address.name = @"John Smith Doe";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.line1 = @"55 John St";
    address.city = @"Harare";
    address.postalCode = @"10002";
    address.country = @"ZW"; // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"ZW"]);
    XCTAssertTrue([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"US"]);

    STPShippingAddressViewController *sut = [[STPShippingAddressViewController alloc] initWithConfiguration:config
                                                                                                      theme:[STPTheme defaultTheme]
                                                                                                   currency:nil
                                                                                            shippingAddress:address
                                                                                     selectedShippingMethod:nil
                                                                                       prefilledInformation:nil];

    XCTAssertNoThrow([sut loadView]);
    XCTAssertNoThrow([sut viewDidLoad]);
}

- (void)testPrefilledBillingAddress_addAddress {
    [NSLocale stp_setCurrentLocale:[NSLocale localeWithLocaleIdentifier:@"en_ZW"]];
    // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"ZW"]);
    XCTAssertTrue([STPPostalCodeValidator postalCodeIsRequiredForCountryCode:@"US"]);
    STPPaymentConfiguration *config = [STPFixtures paymentConfiguration];
    config.requiredShippingAddressFields = [NSSet setWithObject:STPContactFieldPostalAddress];

    STPAddress *address = [STPAddress new];
    address.name = @"John Smith Doe";
    address.phone = @"8885551212";
    address.email = @"foo@example.com";
    address.line1 = @"55 John St";
    address.city = @"New York";
    address.state = @"NY";
    address.postalCode = @"10002";
    address.country = @"US";

    STPShippingAddressViewController *sut = [[STPShippingAddressViewController alloc] initWithConfiguration:config
                                                                                                      theme:[STPTheme defaultTheme]
                                                                                                   currency:nil
                                                                                            shippingAddress:address
                                                                                     selectedShippingMethod:nil
                                                                                       prefilledInformation:nil];

    XCTAssertNoThrow([sut loadView]);
    XCTAssertNoThrow([sut viewDidLoad]);
    [NSLocale stp_resetCurrentLocale];
}


@end
