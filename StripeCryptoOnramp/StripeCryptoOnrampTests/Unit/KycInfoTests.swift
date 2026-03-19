//
//  KycInfoTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 3/19/26.
//

import Contacts
import PassKit

@testable
@_spi(CryptoOnrampAlpha)
import StripeCryptoOnramp

import XCTest

final class KycInfoTests: XCTestCase {

    func testInitPaymentReturnsNilWhenBillingContactIsMissing() {
        let payment = createMockPayment(billingContact: nil)

        XCTAssertNil(KycInfo(payment: payment))
    }

    func testInitPaymentReturnsKycInfoForBillingNameOnly() {
        let billingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Smith"
        billingContact.name = name

        let payment = createMockPayment(billingContact: billingContact)
        let kycInfo = KycInfo(payment: payment)

        XCTAssertEqual(
            kycInfo,
            KycInfo(
                firstName: "John",
                lastName: "Smith",
                idNumber: nil,
                address: nil,
                dateOfBirth: nil
            )
        )
    }

    func testInitPaymentReturnsKycInfoForBillingAddressOnly() {
        let billingContact = PKContact()
        let postalAddress = CNMutablePostalAddress()
        postalAddress.street = "123 Main St\nApt 2"
        postalAddress.city = "New York"
        postalAddress.state = "NY"
        postalAddress.postalCode = "10001"
        postalAddress.isoCountryCode = "US"
        billingContact.postalAddress = postalAddress

        let payment = createMockPayment(billingContact: billingContact)
        let kycInfo = KycInfo(payment: payment)

        XCTAssertEqual(
            kycInfo,
            KycInfo(
                firstName: nil,
                lastName: nil,
                idNumber: nil,
                address: Address(
                    city: "New York",
                    country: "US",
                    line1: "123 Main St\nApt 2",
                    line2: nil,
                    postalCode: "10001",
                    state: "NY"
                ),
                dateOfBirth: nil
            )
        )
    }

    func testInitPaymentReturnsKycInfoForPartialBillingName() {
        let billingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        billingContact.name = name

        let payment = createMockPayment(billingContact: billingContact)
        let kycInfo = KycInfo(payment: payment)

        XCTAssertEqual(
            kycInfo,
            KycInfo(
                firstName: "John",
                lastName: nil,
                idNumber: nil,
                address: nil,
                dateOfBirth: nil
            )
        )
    }

    func testInitPaymentReturnsNilWhenBillingContactHasNoUsableFields() {
        let billingContact = PKContact()
        billingContact.name = PersonNameComponents()
        billingContact.postalAddress = CNMutablePostalAddress()

        let payment = createMockPayment(billingContact: billingContact)

        XCTAssertNil(KycInfo(payment: payment))
    }

    private func createMockPayment(billingContact: PKContact?) -> PKPayment {
        let payment = PKPayment()
        payment.setValue(billingContact, forKey: "billingContact")
        return payment
    }
}
