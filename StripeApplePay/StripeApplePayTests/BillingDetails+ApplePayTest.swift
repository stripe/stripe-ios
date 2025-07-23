//
//  BillingDetails+ApplePayTest.swift
//  StripeApplePayTests
//
//  Created by Claude on 7/23/25.
//

import Contacts
import PassKit
@testable import StripeApplePay
@_spi(STP) import StripeCore
import XCTest

final class BillingDetailsApplePayTest: XCTestCase {

    func testBillingDetailsInit_withBillingContact() {
        let contact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Doe"
        contact.name = name
        contact.emailAddress = "john@example.com"
        contact.phoneNumber = CNPhoneNumber(stringValue: "+1234567890")

        let address = CNMutablePostalAddress()
        address.street = "123 Main St"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "10001"
        address.isoCountryCode = "US"
        contact.postalAddress = address

        let payment = createMockPKPayment(billingContact: contact, shippingContact: nil)
        let billingDetails = StripeAPI.BillingDetails(from: payment)

        XCTAssertNotNil(billingDetails)
        XCTAssertEqual(billingDetails?.name, "John Doe")
        XCTAssertEqual(billingDetails?.email, "john@example.com")
        XCTAssertEqual(billingDetails?.phone, "1234567890")
        XCTAssertEqual(billingDetails?.address?.line1, "123 Main St")
        XCTAssertEqual(billingDetails?.address?.city, "New York")
        XCTAssertEqual(billingDetails?.address?.state, "NY")
        XCTAssertEqual(billingDetails?.address?.postalCode, "10001")
        XCTAssertEqual(billingDetails?.address?.country, "US")
    }

    func testBillingDetailsInit_withShippingContactForEmailAndPhone() {
        // Create billing contact with address and name only
        let billingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Doe"
        billingContact.name = name

        let address = CNMutablePostalAddress()
        address.street = "123 Main St"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "10001"
        address.isoCountryCode = "US"
        billingContact.postalAddress = address

        // Create shipping contact with email and phone
        let shippingContact = PKContact()
        shippingContact.emailAddress = "john@example.com"
        shippingContact.phoneNumber = CNPhoneNumber(stringValue: "+1234567890")

        let payment = createMockPKPayment(billingContact: billingContact, shippingContact: shippingContact)
        let billingDetails = StripeAPI.BillingDetails(from: payment)

        XCTAssertNotNil(billingDetails)
        XCTAssertEqual(billingDetails?.name, "John Doe")
        XCTAssertEqual(billingDetails?.email, "john@example.com") // From shipping
        XCTAssertEqual(billingDetails?.phone, "1234567890") // From shipping
        XCTAssertEqual(billingDetails?.address?.line1, "123 Main St")
        XCTAssertEqual(billingDetails?.address?.city, "New York")
        XCTAssertEqual(billingDetails?.address?.state, "NY")
        XCTAssertEqual(billingDetails?.address?.postalCode, "10001")
        XCTAssertEqual(billingDetails?.address?.country, "US")
    }

    func testBillingDetailsInit_onlyShippingContact() {
        let shippingContact = PKContact()
        shippingContact.emailAddress = "shipping@example.com"
        shippingContact.phoneNumber = CNPhoneNumber(stringValue: "+1234567890")

        let payment = createMockPKPayment(billingContact: nil, shippingContact: shippingContact)
        let billingDetails = StripeAPI.BillingDetails(from: payment)

        XCTAssertNotNil(billingDetails)
        XCTAssertNil(billingDetails?.name)
        XCTAssertEqual(billingDetails?.email, "shipping@example.com")
        XCTAssertEqual(billingDetails?.phone, "1234567890")
        XCTAssertNil(billingDetails?.address)
    }

    func testBillingDetailsInit_noContacts() {
        let payment = createMockPKPayment(billingContact: nil, shippingContact: nil)
        let billingDetails = StripeAPI.BillingDetails(from: payment)

        XCTAssertNil(billingDetails)
    }

    func testBillingDetailsInit_emptyContacts() {
        let billingContact = PKContact()
        let shippingContact = PKContact()

        let payment = createMockPKPayment(billingContact: billingContact, shippingContact: shippingContact)
        let billingDetails = StripeAPI.BillingDetails(from: payment)

        XCTAssertNil(billingDetails?.name)
        XCTAssertNil(billingDetails?.email)
        XCTAssertNil(billingDetails?.phone)
        XCTAssertNil(billingDetails?.address)
    }

    func testBillingDetailsInit_partialShippingFallback() {
        // Billing contact with name only
        let billingContact = PKContact()
        var name = PersonNameComponents()
        name.givenName = "John"
        name.familyName = "Doe"
        billingContact.name = name

        // Shipping contact with phone only
        let shippingContact = PKContact()
        shippingContact.phoneNumber = CNPhoneNumber(stringValue: "+1234567890")

        let payment = createMockPKPayment(billingContact: billingContact, shippingContact: shippingContact)
        let billingDetails = StripeAPI.BillingDetails(from: payment)

        XCTAssertNotNil(billingDetails)
        XCTAssertEqual(billingDetails?.name, "John Doe")
        XCTAssertNil(billingDetails?.email) // No email provided
        XCTAssertEqual(billingDetails?.phone, "1234567890") // From shipping
        XCTAssertNil(billingDetails?.address)
    }

    // MARK: - Helper Methods

    private func createMockPKPayment(billingContact: PKContact?, shippingContact: PKContact?) -> PKPayment {
        let payment = PKPayment()
        payment.setValue(billingContact, forKey: "billingContact")
        payment.setValue(shippingContact, forKey: "shippingContact")
        return payment
    }
}
