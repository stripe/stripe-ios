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

    func testInitDefaultsEmailAndPhoneToNil() {
        let kycInfo = KycInfo(
            firstName: "John",
            lastName: "Smith",
            idNumber: nil,
            address: nil,
            dateOfBirth: nil
        )

        XCTAssertNil(kycInfo.email)
        XCTAssertNil(kycInfo.phone)
    }

    func testInitPaymentReturnsNilWhenBillingContactIsMissing() {
        let payment = createMockPayment(billingContact: nil)

        XCTAssertNil(KycInfo(payment: payment))
    }

    func testInitPaymentReturnsNilForEmailOnly() {
        // Given a billing contact containing only an email address
        let billingContact = PKContact()
        billingContact.emailAddress = "test@example.com"

        // When creating KYC info from the payment
        let payment = createMockPayment(billingContact: billingContact)

        // Then no KYC info is produced
        XCTAssertNil(KycInfo(payment: payment))
    }

    func testInitPaymentReturnsNilForPhoneOnly() {
        // Given a billing contact containing only a display-formatted phone number
        let billingContact = PKContact()
        billingContact.phoneNumber = CNPhoneNumber(stringValue: "(212) 555-1234")

        // When creating KYC info from the payment
        let payment = createMockPayment(billingContact: billingContact)

        // Then no KYC info is produced
        XCTAssertNil(KycInfo(payment: payment))
    }

    func testInitPaymentReadsContactFieldsFromShippingContactWhenAbsentOnBillingContact() {
        // Given a name on the billing contact and contact fields on the shipping contact
        let billingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Smith"
        billingContact.name = name

        let shippingContact = PKContact()
        shippingContact.emailAddress = "test@example.com"
        shippingContact.phoneNumber = CNPhoneNumber(stringValue: "+12125551234")

        // When creating KYC info from the payment
        let payment = createMockPayment(billingContact: billingContact, shippingContact: shippingContact)
        let kycInfo = KycInfo(payment: payment)

        // Then fields from both contacts are mapped
        XCTAssertEqual(
            kycInfo,
            KycInfo(
                firstName: "John",
                lastName: "Smith",
                idNumber: nil,
                address: nil,
                dateOfBirth: nil,
                email: "test@example.com",
                phone: "+12125551234"
            )
        )
    }

    func testInitPaymentPrefersBillingContactContactFields() {
        // Given a billing name and contact fields on both the billing and shipping contacts
        let billingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "Test"
        billingContact.name = name
        billingContact.emailAddress = "billing@example.com"

        let shippingContact = PKContact()
        shippingContact.emailAddress = "shipping@example.com"

        // When creating KYC info from the payment
        let payment = createMockPayment(billingContact: billingContact, shippingContact: shippingContact)
        let kycInfo = KycInfo(payment: payment)

        // Then the billing contact value is used
        XCTAssertEqual(kycInfo?.email, "billing@example.com")
    }

    func testInitPaymentDropsWhitespaceOnlyContactFields() {
        // Given whitespace-only contact fields
        let billingContact = PKContact()
        billingContact.emailAddress = " "
        billingContact.phoneNumber = CNPhoneNumber(stringValue: " ")

        // When creating KYC info from the payment
        let payment = createMockPayment(billingContact: billingContact)

        // Then no KYC info is produced
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

    func testInitPaymentReturnsKycInfoForShippingNameOnly() {
        // Given a shipping name without a billing contact
        let shippingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = " ShippingFirst "
        name.familyName = " ShippingLast "
        shippingContact.name = name

        // When creating KYC info from the payment
        let payment = createMockPayment(billingContact: nil, shippingContact: shippingContact)
        let kycInfo = KycInfo(payment: payment)

        // Then the trimmed shipping name is used
        XCTAssertEqual(kycInfo?.firstName, "ShippingFirst")
        XCTAssertEqual(kycInfo?.lastName, "ShippingLast")
    }

    func testInitPaymentFallsBackToShippingNamePerField() {
        let billingNames: [(givenName: String?, familyName: String?)] = [
            (nil, " BillingLast "),
            (" BillingFirst ", nil),
            (" \n", " BillingLast "),
            (" BillingFirst ", " \n"),
            ("", ""),
            (" BillingFirst ", " BillingLast "),
        ]

        for billingName in billingNames {
            // Given billing name fields and a complete shipping name
            let billingContact = PKContact()
            var name = PersonNameComponents()
            name.givenName = billingName.givenName
            name.familyName = billingName.familyName
            billingContact.name = name

            let shippingContact = PKContact()
            var shippingName = PersonNameComponents()
            shippingName.givenName = " ShippingFirst "
            shippingName.familyName = " ShippingLast "
            shippingContact.name = shippingName

            // When creating KYC info from the payment
            let payment = createMockPayment(billingContact: billingContact, shippingContact: shippingContact)
            let kycInfo = KycInfo(payment: payment)

            // Then each usable billing field takes precedence independently
            XCTAssertEqual(kycInfo?.firstName, billingName.givenName == " BillingFirst " ? "BillingFirst" : "ShippingFirst")
            XCTAssertEqual(kycInfo?.lastName, billingName.familyName == " BillingLast " ? "BillingLast" : "ShippingLast")
        }
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

    func testInitPaymentReturnsNilWhenBillingContactHasWhitespaceFields() {
        let billingContact = PKContact()
        var nameComponents = PersonNameComponents()
        nameComponents.familyName = " "
        nameComponents.givenName = " "
        billingContact.postalAddress = CNMutablePostalAddress()

        let payment = createMockPayment(billingContact: billingContact)

        XCTAssertNil(KycInfo(payment: payment))
    }

    private func createMockPayment(billingContact: PKContact?, shippingContact: PKContact? = nil) -> PKPayment {
        let payment = PKPayment()
        payment.setValue(billingContact, forKey: "billingContact")
        payment.setValue(shippingContact, forKey: "shippingContact")
        return payment
    }
}
