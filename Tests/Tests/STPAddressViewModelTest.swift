//
//  STPAddressViewModelTest.swift
//  Stripe
//
//  Created by Ben Guo on 10/21/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPAddressViewModelTest: XCTestCase {
  func testInitWithRequiredBillingFields() {
    var sut = STPAddressViewModel(requiredBillingFields: .none, availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 0)
    XCTAssertTrue(sut.isValid)

    sut = STPAddressViewModel(requiredBillingFields: .postalCode, availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 0)

    sut = STPAddressViewModel(requiredBillingFields: .full, availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 7)
    let types: [STPAddressFieldType] = [
      .name,
      .line1,
      .line2,
      .country,
      .zip,
      .city,
      .state,
    ]
    for i in 0..<sut.addressCells.count {
      XCTAssertEqual(sut.addressCells[i].type, types[i])
    }

    sut = STPAddressViewModel(requiredBillingFields: .name, availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 1)
    XCTAssertEqual(sut.addressCells[0].type, .name)
  }

  func testInitWithRequiredShippingFields() {
    var sut = STPAddressViewModel(
      requiredShippingFields: Set<STPContactField>(), availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 0)

    sut = STPAddressViewModel(
      requiredShippingFields: Set<STPContactField>([.name]), availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 1)
    let cell1 = sut.addressCells[0]
    XCTAssertEqual(cell1.type, .name)

    sut = STPAddressViewModel(
      requiredShippingFields: Set<STPContactField>([.name, .emailAddress]), availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 2)
    var types: [STPAddressFieldType] = [.name, .email]
    for i in 0..<sut.addressCells.count {
      XCTAssertEqual(sut.addressCells[i].type, types[i])
    }

    sut = STPAddressViewModel(
      requiredShippingFields: Set<STPContactField>([
        .postalAddress, .emailAddress, .phoneNumber,
      ]), availableCountries: nil)
    XCTAssertTrue(sut.addressCells.count == 9)
    types = [
      .email,
      .name,
      .line1,
      .line2,
      .country,
      .zip,
      .city,
      .state,
      .phone,
    ]
    for i in 0..<sut.addressCells.count {
      XCTAssertEqual(sut.addressCells[i].type, types[i])
    }
  }

  func testGetAddress() {
    let sut = STPAddressViewModel(
      requiredShippingFields: Set<STPContactField>([
        .postalAddress,
        .emailAddress,
        .phoneNumber,
      ]), availableCountries: nil)
    sut.addressCells[0].contents = "foo@example.com"
    sut.addressCells[1].contents = "John Smith"
    sut.addressCells[2].contents = "55 John St"
    sut.addressCells[3].contents = "#3B"
    sut.addressCells[4].contents = "US"
    sut.addressCells[5].contents = "10002"
    sut.addressCells[6].contents = "New York"
    sut.addressCells[7].contents = "NY"
    sut.addressCells[8].contents = "555-555-5555"

    XCTAssertEqual(sut.address.email, "foo@example.com")
    XCTAssertEqual(sut.address.name, "John Smith")
    XCTAssertEqual(sut.address.line1, "55 John St")
    XCTAssertEqual(sut.address.line2, "#3B")
    XCTAssertEqual(sut.address.city, "New York")
    XCTAssertEqual(sut.address.state, "NY")
    XCTAssertEqual(sut.address.postalCode, "10002")
    XCTAssertEqual(sut.address.country, "US")
    XCTAssertEqual(sut.address.phone, "555-555-5555")
  }

  func testSetAddress() {
    let address = STPAddress()
    address.email = "foo@example.com"
    address.name = "John Smith"
    address.line1 = "55 John St"
    address.line2 = "#3B"
    address.city = "New York"
    address.state = "NY"
    address.postalCode = "10002"
    address.country = "US"
    address.phone = "555-555-5555"

    let sut = STPAddressViewModel(
      requiredShippingFields: Set<STPContactField>([
        .postalAddress,
        .emailAddress,
        .phoneNumber,
      ]), availableCountries: nil)
    sut.address = address
    XCTAssertEqual(sut.addressCells[0].contents, "foo@example.com")
    XCTAssertEqual(sut.addressCells[1].contents, "John Smith")
    XCTAssertEqual(sut.addressCells[2].contents, "55 John St")
    XCTAssertEqual(sut.addressCells[3].contents, "#3B")
    XCTAssertEqual(sut.addressCells[4].contents, "US")
    XCTAssertEqual(sut.addressCells[4].textField?.text, "United States")
    XCTAssertEqual(sut.addressCells[5].contents, "10002")
    XCTAssertEqual(sut.addressCells[6].contents, "New York")
    XCTAssertEqual(sut.addressCells[7].contents, "NY")
    XCTAssertEqual(sut.addressCells[8].contents, "555-555-5555")
  }

  func testIsValid_Zip() {
    let sut = STPAddressViewModel(requiredBillingFields: .postalCode, availableCountries: nil)

    let address = STPAddress()

    address.country = "US"
    sut.address = address
    XCTAssertEqual(sut.addressCells.count, 0)  // The AddressViewModel shouldn't request any information when requesting ZIPs.

    address.postalCode = "94016"
    sut.address = address
    XCTAssertTrue(sut.isValid)

    address.country = "MO"  // in Macao, postalCode is optional
    address.postalCode = nil
    sut.address = address
    XCTAssertEqual(sut.addressCells.count, 0)
    XCTAssertTrue(sut.isValid, "in Macao, postalCode is optional, valid without one")
  }

  func testIsValid_Full() {
    let sut = STPAddressViewModel(requiredBillingFields: .full, availableCountries: nil)
    XCTAssertFalse(sut.isValid)
    sut.addressCells[0].contents = "John Smith"
    sut.addressCells[1].contents = "55 John St"
    sut.addressCells[2].contents = "#3B"
    XCTAssertFalse(sut.isValid)
    sut.addressCells[3].contents = "10002"
    sut.addressCells[4].contents = "New York"
    sut.addressCells[5].contents = "NY"
    sut.addressCells[6].contents = "US"
    XCTAssertTrue(sut.isValid)
  }

  func testIsValid_Name() {
    let sut = STPAddressViewModel(requiredBillingFields: .name, availableCountries: nil)

    let address = STPAddress()

    address.name = ""
    sut.address = address
    XCTAssertEqual(sut.addressCells.count, 1)
    XCTAssertFalse(sut.isValid)

    address.name = "Jane Doe"
    sut.address = address
    XCTAssertEqual(sut.addressCells.count, 1)
    XCTAssertTrue(sut.isValid)
  }
}
