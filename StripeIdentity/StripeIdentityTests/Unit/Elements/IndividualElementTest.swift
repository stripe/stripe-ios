//
//  IndividualElementTest.swift
//  StripeIdentityTests
//
//  Created by Chen Cen on 2/6/23.
//

@_spi(STP)@testable import StripeIdentity
import XCTest

final class IndividualElementTest: XCTestCase {
    private let content: StripeAPI.VerificationPageStaticContentIndividualPage = .init(
        addressCountries: ["US": "United States"],
        buttonText: "Cancel",
        title: "Provide personal information",
        idNumberCountries: ["US": "United States"],
        idNumberCountryNotListedTextButtonText: "id country not listed",
        addressCountryNotListedTextButtonText: "address country not listed"
    )

    func testMissingIdNumberOnly() {
        let element = IndividualFormElement(
            individualContent: content,
            missing: [.idNumber],
            countryNotListedButtonClicked: { _ in }
        )

        XCTAssertNil(element.nameElement)
        XCTAssertNil(element.dobElement)
        XCTAssertNil(element.addressElement)
        XCTAssertNil(element.addressCountryNotListedButtonElement)
        XCTAssertNotNil(element.idNumberElement)
        XCTAssertNotNil(element.idCountryNotListedButtonElement)

    }

    func testMissingAddressOnly() {
        let element = IndividualFormElement(
            individualContent: content,
            missing: [.address],
            countryNotListedButtonClicked: { _ in }
        )

        XCTAssertNil(element.nameElement)
        XCTAssertNil(element.dobElement)
        XCTAssertNotNil(element.addressElement)
        XCTAssertNotNil(element.addressCountryNotListedButtonElement)
        XCTAssertNil(element.idNumberElement)
        XCTAssertNil(element.idCountryNotListedButtonElement)
    }

    func testMissingDobNameIdNumber() {
        let element = IndividualFormElement(
            individualContent: content,
            missing: [.dob, .name, .idNumber],
            countryNotListedButtonClicked: { _ in }
        )

        XCTAssertNotNil(element.nameElement)
        XCTAssertNotNil(element.dobElement)
        XCTAssertNil(element.addressElement)
        XCTAssertNil(element.addressCountryNotListedButtonElement)
        XCTAssertNotNil(element.idNumberElement)
        XCTAssertNotNil(element.idCountryNotListedButtonElement)

    }

    func testMissingDobNameAddres() {
        let element = IndividualFormElement(
            individualContent: content,
            missing: [.dob, .name, .address],
            countryNotListedButtonClicked: { _ in }
        )

        XCTAssertNotNil(element.nameElement)
        XCTAssertNotNil(element.dobElement)
        XCTAssertNotNil(element.addressElement)
        XCTAssertNotNil(element.addressCountryNotListedButtonElement)
        XCTAssertNil(element.idNumberElement)
        XCTAssertNil(element.idCountryNotListedButtonElement)

    }
}
