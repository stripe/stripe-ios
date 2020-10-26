//
//  STPShippingAddressViewControllerTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 8/7/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Stripe

@testable import Stripe

class STPShippingAddressViewControllerTest: XCTestCase {
  func testPrefilledBillingAddress_removeAddress() {
    let config = STPFixtures.paymentConfiguration()
    config?.requiredShippingAddressFields = Set<STPContactField>([.postalAddress])

    let address = STPAddress()
    address.name = "John Smith Doe"
    address.phone = "8885551212"
    address.email = "foo@example.com"
    address.line1 = "55 John St"
    address.city = "Harare"
    address.postalCode = "10002"
    address.country = "ZW"  // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
    XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))

    let sut = STPShippingAddressViewController(
      configuration: config,
      theme: STPTheme.defaultTheme,
      currency: nil,
      shippingAddress: address,
      selectedShippingMethod: nil,
      prefilledInformation: nil)

    XCTAssertNoThrow(sut.loadView())
    XCTAssertNoThrow(sut.viewDidLoad())
  }

  func testPrefilledBillingAddress_addAddressWithLimitedCountries() {
    NSLocale.stp_setCurrentLocale(NSLocale(localeIdentifier: "en_ZW") as Locale)
    // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
    XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))
    let config = STPFixtures.paymentConfiguration()
    config?.requiredShippingAddressFields = Set<STPContactField>([.postalAddress])
    config?.availableCountries = Set<String>(["CA", "BT"])

    let address = STPAddress()
    address.name = "John Smith Doe"
    address.phone = "8885551212"
    address.email = "foo@example.com"
    address.line1 = "55 John St"
    address.city = "New York"
    address.state = "NY"
    address.postalCode = "10002"
    address.country = "US"

    let sut = STPShippingAddressViewController(
      configuration: config,
      theme: STPTheme.defaultTheme,
      currency: nil,
      shippingAddress: address,
      selectedShippingMethod: nil,
      prefilledInformation: nil)

    XCTAssertNoThrow(sut.loadView())
    XCTAssertNoThrow(sut.viewDidLoad())
    NSLocale.stp_resetCurrentLocale()
  }

  func testPrefilledBillingAddress_addAddress() {
    NSLocale.stp_setCurrentLocale(NSLocale(localeIdentifier: "en_ZW") as Locale)
    // Zimbabwe does not require zip codes, while the default locale for tests (US) does
    // Sanity checks
    XCTAssertFalse(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "ZW"))
    XCTAssertTrue(STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: "US"))
    let config = STPFixtures.paymentConfiguration()
    config?.requiredShippingAddressFields = Set<STPContactField>([.postalAddress])

    let address = STPAddress()
    address.name = "John Smith Doe"
    address.phone = "8885551212"
    address.email = "foo@example.com"
    address.line1 = "55 John St"
    address.city = "New York"
    address.state = "NY"
    address.postalCode = "10002"
    address.country = "US"

    let sut = STPShippingAddressViewController(
      configuration: config,
      theme: STPTheme.defaultTheme,
      currency: nil,
      shippingAddress: address,
      selectedShippingMethod: nil,
      prefilledInformation: nil)

    XCTAssertNoThrow(sut.loadView())
    XCTAssertNoThrow(sut.viewDidLoad())
    NSLocale.stp_resetCurrentLocale()
  }
}
