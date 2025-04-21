//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPAddressTests.m
//  Stripe
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Contacts
import PassKit

class STPAddressTests: XCTestCase {
    func testInitWithPKContact_complete() {
        let contact = PKContact()
        do {
            var name = PersonNameComponents()
            name.givenName = "John"
            name.familyName = "Doe"
            contact.name = name

            contact.emailAddress = "foo@example.com"
            contact.phoneNumber = CNPhoneNumber(stringValue: "888-555-1212")

            let address = CNMutablePostalAddress()
            address.street = "55 John St"
            address.city = "New York"
            address.state = "NY"
            address.postalCode = "10002"
            address.isoCountryCode = "US"
            address.country = "United States"
            contact.postalAddress = address
        }

        let address = STPAddress(pkContact: contact)
        XCTAssertEqual("John Doe", address.name)
        XCTAssertEqual("8885551212", address.phone)
        XCTAssertEqual("foo@example.com", address.email)
        XCTAssertEqual("55 John St", address.line1)
        XCTAssertEqual("New York", address.city)
        XCTAssertEqual("NY", address.state)
        XCTAssertEqual("10002", address.postalCode)
        XCTAssertEqual("US", address.country)
    }

    func testInitWithPKContact_partial() {
        let contact = PKContact()
        do {
            var name = PersonNameComponents()
            name.givenName = "John"
            contact.name = name

            let address = CNMutablePostalAddress()
            address.state = "VA"
            contact.postalAddress = address
        }

        let address = STPAddress(pkContact: contact)
        XCTAssertEqual("John", address.name)
        XCTAssertNil(address.phone)
        XCTAssertNil(address.email)
        XCTAssertNil(address.line1)
        XCTAssertNil(address.city)
        XCTAssertEqual("VA", address.state)
        XCTAssertNil(address.postalCode)
        XCTAssertNil(address.country)
    }

    func testInitWithCNContact_complete() {
        let contact = CNMutableContact()
        do {
            contact.givenName = "John"
            contact.familyName = "Doe"

            contact.emailAddresses = [
                CNLabeledValue(
                                label: CNLabelHome,
                                value: "foo@example.com"),
                CNLabeledValue(
                                label: CNLabelWork,
                                value: "bar@example.com"),
            ]

            contact.phoneNumbers = [
                CNLabeledValue(
                                label: CNLabelHome,
                                value: CNPhoneNumber(stringValue: "888-555-1212")),
                CNLabeledValue(
                                label: CNLabelWork,
                                value: CNPhoneNumber(stringValue: "555-555-5555")),
            ]

            let address = CNMutablePostalAddress()
            address.street = "55 John St"
            address.city = "New York"
            address.state = "NY"
            address.postalCode = "10002"
            address.isoCountryCode = "US"
            address.country = "United States"
            contact.postalAddresses = [
                CNLabeledValue(
                                label: CNLabelHome,
                                value: address),
            ]
        }

        let address = STPAddress(cnContact: contact)
        XCTAssertEqual("John Doe", address.name)
        XCTAssertEqual("8885551212", address.phone)
        XCTAssertEqual("foo@example.com", address.email)
        XCTAssertEqual("55 John St", address.line1)
        XCTAssertEqual("New York", address.city)
        XCTAssertEqual("NY", address.state)
        XCTAssertEqual("10002", address.postalCode)
        XCTAssertEqual("US", address.country)
    }

    func testInitWithCNContact_partial() {
        let contact = CNMutableContact()
        do {
            contact.givenName = "John"

            let address = CNMutablePostalAddress()
            address.state = "VA"
            contact.postalAddresses = [
                CNLabeledValue(
                                label: CNLabelHome,
                                value: address),
            ]
        }

        let address = STPAddress(cnContact: contact)
        XCTAssertEqual("John", address.name)
        XCTAssertNil(address.phone)
        XCTAssertNil(address.email)
        XCTAssertNil(address.line1)
        XCTAssertNil(address.city)
        XCTAssertEqual("VA", address.state)
        XCTAssertNil(address.postalCode)
        XCTAssertNil(address.country)
    }

    func testPKContactValue() {
        let address = STPAddress()
        address.name = "John Smith Doe"
        address.phone = "8885551212"
        address.email = "foo@example.com"
        address.line1 = "55 John St"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "10002"
        address.country = "US"

        let contact = address.pkContactValue()
        XCTAssertEqual(contact.name?.givenName, "John")
        XCTAssertEqual(contact.name?.familyName, "Smith Doe")
        XCTAssertEqual(contact.phoneNumber?.stringValue, "8885551212")
        XCTAssertEqual(contact.emailAddress, "foo@example.com")
        let postalAddress = contact.postalAddress
        XCTAssertEqual(postalAddress?.street, "55 John St")
        XCTAssertEqual(postalAddress?.city, "New York")
        XCTAssertEqual(postalAddress?.state, "NY")
        XCTAssertEqual(postalAddress?.postalCode, "10002")
        XCTAssertEqual(postalAddress?.country, "US")
    }

    func testShippingInfoForCharge() {
        let address = STPFixtures.address()
        let method = PKShippingMethod()
        method.label = "UPS Ground"
        let info = STPAddress.shippingInfoForCharge(
            with: address,
            shippingMethod: method) as NSDictionary?
        let expected: NSDictionary = [
            "address": [
            "city": address.city,
            "country": address.country,
            "line1": address.line1,
            "line2": address.line2,
            "postal_code": address.postalCode,
            "state": address.state,
        ],
            "name": address.name as Any,
            "phone": address.phone as Any,
            "carrier": method.label,
        ]
        XCTAssertEqual(expected, info)
    }

    // MARK: STPFormEncodable Tests

    func testRootObjectName() {
        XCTAssertNil(STPAddress.rootObjectName())
    }

    func testPropertyNamesToFormFieldNamesMapping() {
        let address = STPAddress()

        let mapping = STPAddress.propertyNamesToFormFieldNamesMapping()

        for propertyName in mapping.keys {
            XCTAssertFalse(propertyName.contains(":"))
            XCTAssert(address.responds(to: NSSelectorFromString(propertyName)))
        }

        for formFieldName in mapping.values {
            XCTAssert(formFieldName.count > 0)
        }

        XCTAssertEqual(mapping.values.count, mapping.values.count)
    }

    // MARK: NSCopying Tests

    func testCopyWithZone() {
        let address = STPFixtures.address()
        let copiedAddress = address.copy() as! STPAddress

        XCTAssertNotEqual(address, copiedAddress, "should be different objects")

        // The property names we expect to *not* be equal objects
        let notEqualProperties = [
                    // these include the object's address, so they won't be the same across copies
            "debugDescription",
            "description",
            "hash",
        ]
        // use runtime inspection to find the list of properties. If a new property is
        // added to the fixture, but not the `copyWithZone:` implementation, this should catch it
        for property in STPTestUtils.propertyNames(of: address) {
            if notEqualProperties.contains(property) {
                XCTAssertNotEqual(
                    address.value(forKey: property) as! NSObject,
                    copiedAddress.value(forKey: property) as! NSObject)
            } else {
                XCTAssertEqual(
                    address.value(forKey: property) as! NSObject,
                    copiedAddress.value(forKey: property) as! NSObject)
            }
        }
    }
}
