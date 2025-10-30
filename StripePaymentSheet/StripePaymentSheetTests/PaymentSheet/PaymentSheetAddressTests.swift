//
//  PaymentSheetAddressTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 7/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet

class PaymentSheetAddressTests: XCTestCase {

    func testEditDistanceEqualAddress() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: address), 0)
    }

    func testEditDistanceOneCharDiff() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "Sa Francisco",  // One char diff here
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 1)
    }

    func testEditDistanceDifferentCity() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "Freemont",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 11)
    }

    func testEditDistanceMissingCityOriginal() {
        let address = PaymentSheet.Address(
            city: nil,
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 13)
    }

    func testEditDistanceMissingCityOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: nil,
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 13)
    }

    func testEditDistanceMissingCountryOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: nil,
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 2)
    }

    func testEditDistanceMissingCountryOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: nil,
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 2)
    }

    func testEditDistanceMissingLineOneOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: nil,
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 16)
    }

    func testEditDistanceMissingLineOneOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: nil,
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 16)
    }

    func testEditDistanceMissingLineTwoOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: nil,
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: "Apt. 112",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 8)
    }

    func testEditDistanceMissingLineTwoOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: "Apt. 112",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: nil,
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 8)
    }

    func testEditDistanceMissingPostalCodeOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: nil,
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 5)
    }

    func testEditDistanceMissingPostalCodeOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: nil,
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 5)
    }

    func testEditDistanceMissingStateOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: nil
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 10)
    }

    func testEditDistanceMissingStateOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )

        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: nil
        )

        XCTAssertEqual(address.editDistance(from: otherAddress), 10)
    }

    // MARK: - paymentIntentShippingDetailsParams Tests

    func testPaymentIntentShippingDetailsParamsReturnsNilWhenNameIsNil() {
        let address = AddressViewController.AddressDetails.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: nil,
            postalCode: "94102",
            state: "CA"
        )

        let addressDetails = AddressViewController.AddressDetails(
            address: address,
            name: nil,
            phone: "+15551234567"
        )

        XCTAssertNil(addressDetails.paymentIntentShippingDetailsParams)
    }

    func testPaymentIntentShippingDetailsParamsWithCompleteValidData() {
        let address = AddressViewController.AddressDetails.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "Apt 123",
            postalCode: "94102",
            state: "CA"
        )

        let addressDetails = AddressViewController.AddressDetails(
            address: address,
            name: "John Doe",
            phone: "+15551234567"
        )

        let shippingParams = addressDetails.paymentIntentShippingDetailsParams

        XCTAssertNotNil(shippingParams)
        XCTAssertEqual(shippingParams?.name, "John Doe")
        XCTAssertEqual(shippingParams?.phone, "+15551234567")

        let addressParams = shippingParams?.address
        XCTAssertNotNil(addressParams)
        XCTAssertEqual(addressParams?.line1, "510 Townsend St.")
        XCTAssertEqual(addressParams?.line2, "Apt 123")
        XCTAssertEqual(addressParams?.city, "San Francisco")
        XCTAssertEqual(addressParams?.state, "CA")
        XCTAssertEqual(addressParams?.postalCode, "94102")
        XCTAssertEqual(addressParams?.country, "US")
    }

    func testPaymentIntentShippingDetailsParamsWithMinimalValidData() {
        let address = AddressViewController.AddressDetails.Address(
            country: "US",
            line1: "510 Townsend St."
        )

        let addressDetails = AddressViewController.AddressDetails(
            address: address,
            name: "Jane Smith"
        )

        let shippingParams = addressDetails.paymentIntentShippingDetailsParams

        XCTAssertNotNil(shippingParams)
        XCTAssertEqual(shippingParams?.name, "Jane Smith")
        XCTAssertNil(shippingParams?.phone)

        let addressParams = shippingParams?.address
        XCTAssertNotNil(addressParams)
        XCTAssertEqual(addressParams?.line1, "510 Townsend St.")
        XCTAssertNil(addressParams?.line2)
        XCTAssertNil(addressParams?.city)
        XCTAssertNil(addressParams?.state)
        XCTAssertNil(addressParams?.postalCode)
        XCTAssertEqual(addressParams?.country, "US")
    }

    func testPaymentIntentShippingDetailsParamsWithMissingOptionalAddressFields() {
        let address = AddressViewController.AddressDetails.Address(
            city: nil,
            country: "US",
            line1: "123 Main St.",
            line2: nil,
            postalCode: nil,
            state: nil
        )

        let addressDetails = AddressViewController.AddressDetails(
            address: address,
            name: "Test User"
        )

        let shippingParams = addressDetails.paymentIntentShippingDetailsParams

        XCTAssertNotNil(shippingParams)
        XCTAssertEqual(shippingParams?.name, "Test User")

        let addressParams = shippingParams?.address
        XCTAssertNotNil(addressParams)
        XCTAssertEqual(addressParams?.line1, "123 Main St.")
        XCTAssertNil(addressParams?.line2)
        XCTAssertNil(addressParams?.city)
        XCTAssertNil(addressParams?.state)
        XCTAssertNil(addressParams?.postalCode)
        XCTAssertEqual(addressParams?.country, "US")
    }

    func testPaymentIntentShippingDetailsParamsWithDifferentCountryCodes() {
        let testCases = [
            ("GB", "United Kingdom"),
            ("CA", "Canada"),
            ("AU", "Australia"),
            ("DE", "Germany"),
        ]

        for (countryCode, _) in testCases {
            let address = AddressViewController.AddressDetails.Address(
                city: "Test City",
                country: countryCode,
                line1: "Test Address",
                line2: nil,
                postalCode: "12345",
                state: nil
            )

            let addressDetails = AddressViewController.AddressDetails(
                address: address,
                name: "Test User"
            )

            let shippingParams = addressDetails.paymentIntentShippingDetailsParams

            XCTAssertNotNil(shippingParams, "Should create params for country: \(countryCode)")
            XCTAssertEqual(shippingParams?.address.country, countryCode, "Country should match for: \(countryCode)")
        }
    }

    func testPaymentIntentShippingDetailsParamsPhoneNumberHandling() {
        let address = AddressViewController.AddressDetails.Address(
            country: "US",
            line1: "123 Test St."
        )

        // Test with nil phone
        let addressDetailsWithNilPhone = AddressViewController.AddressDetails(
            address: address,
            name: "User One",
            phone: nil
        )

        let shippingParamsNilPhone = addressDetailsWithNilPhone.paymentIntentShippingDetailsParams
        XCTAssertNotNil(shippingParamsNilPhone)
        XCTAssertNil(shippingParamsNilPhone?.phone)

        // Test with valid phone
        let addressDetailsWithPhone = AddressViewController.AddressDetails(
            address: address,
            name: "User Two",
            phone: "+15551234567"
        )

        let shippingParamsWithPhone = addressDetailsWithPhone.paymentIntentShippingDetailsParams
        XCTAssertNotNil(shippingParamsWithPhone)
        XCTAssertEqual(shippingParamsWithPhone?.phone, "+15551234567")

        // Test with empty phone string
        let addressDetailsWithEmptyPhone = AddressViewController.AddressDetails(
            address: address,
            name: "User Three",
            phone: ""
        )

        let shippingParamsEmptyPhone = addressDetailsWithEmptyPhone.paymentIntentShippingDetailsParams
        XCTAssertNotNil(shippingParamsEmptyPhone)
        XCTAssertEqual(shippingParamsEmptyPhone?.phone, "")
    }

    func testPaymentIntentShippingDetailsParamsPropertyMappingConsistency() {
        let address = AddressViewController.AddressDetails.Address(
            city: "Mapping City",
            country: "FR",
            line1: "456 Mapping Ave",
            line2: "Suite 789",
            postalCode: "75001",
            state: "Île-de-France"
        )

        let addressDetails = AddressViewController.AddressDetails(
            address: address,
            name: "Mapping User",
            phone: "+33123456789"
        )

        let shippingParams = addressDetails.paymentIntentShippingDetailsParams

        XCTAssertNotNil(shippingParams)

        // Verify top-level properties
        XCTAssertEqual(shippingParams?.name, addressDetails.name)
        XCTAssertEqual(shippingParams?.phone, addressDetails.phone)

        // Verify nested address properties
        let addressParams = shippingParams?.address
        XCTAssertEqual(addressParams?.line1, addressDetails.address.line1)
        XCTAssertEqual(addressParams?.line2, addressDetails.address.line2)
        XCTAssertEqual(addressParams?.city, addressDetails.address.city)
        XCTAssertEqual(addressParams?.state, addressDetails.address.state)
        XCTAssertEqual(addressParams?.postalCode, addressDetails.address.postalCode)
        XCTAssertEqual(addressParams?.country, addressDetails.address.country)
    }

}
