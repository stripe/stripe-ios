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

    func testContainsRequiredFieldsNone() {
        let address = STPAddress()
        XCTAssertTrue(address.containsRequiredFields(.none))
        address.line1 = "55 John St"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "10002"
        address.country = "US"
        address.phone = "8885551212"
        address.email = "foo@example.com"
        address.name = "John Doe"
        XCTAssertTrue(address.containsRequiredFields(.none))
        address.country = "UK"
        XCTAssertTrue(address.containsRequiredFields(.none))
    }

    func testContainsRequiredFieldsZip() {
        let address = STPAddress()

        // nil country is treated as generic postal requirement
        XCTAssertFalse(address.containsRequiredFields(.postalCode))
        address.country = "IE" // should pass for country which doesn't require zip/postal
        XCTAssertTrue(address.containsRequiredFields(.postalCode))
        address.country = "US"
        XCTAssertFalse(address.containsRequiredFields(.postalCode))
        address.postalCode = "10002"
        XCTAssertTrue(address.containsRequiredFields(.postalCode))
        address.postalCode = "ABCDE"
        XCTAssertFalse(address.containsRequiredFields(.postalCode))
        address.country = "UK" // should pass for alphanumeric countries
        XCTAssertTrue(address.containsRequiredFields(.postalCode))
        address.country = nil // nil treated as alphanumeric
        XCTAssertTrue(address.containsRequiredFields(.postalCode))
    }

    func testContainsRequiredFieldsFull() {
        let address = STPAddress()

        /// Required fields for full are:
        /// line1, city, country, state (US only) and a valid postal code (based on country)

        XCTAssertFalse(address.containsRequiredFields(.full))
        address.country = "US"
        address.line1 = "55 John St"

        // Fail on partial
        XCTAssertFalse(address.containsRequiredFields(.full))

        address.city = "New York"

        // For US fail if missing state or zip
        XCTAssertFalse(address.containsRequiredFields(.full))
        address.state = "NY"
        XCTAssertFalse(address.containsRequiredFields(.full))
        address.postalCode = "ABCDE"
        XCTAssertFalse(address.containsRequiredFields(.full))
        // postal must be numeric for US
        address.postalCode = "10002"
        XCTAssertTrue(address.containsRequiredFields(.full))
        address.phone = "8885551212"
        address.email = "foo@example.com"
        address.name = "John Doe"
        // Name/phone/email should have no effect
        XCTAssertTrue(address.containsRequiredFields(.full))

        // Non US countries don't require state
        address.country = "UK"
        XCTAssertTrue(address.containsRequiredFields(.full))
        address.state = nil
        XCTAssertTrue(address.containsRequiredFields(.full))
        // alphanumeric postal ok in some countries
        address.postalCode = "ABCDE"
        XCTAssertTrue(address.containsRequiredFields(.full))
        // UK requires ZIP
        address.postalCode = nil
        XCTAssertFalse(address.containsRequiredFields(.full))

        address.country = "IE" // Doesn't require postal or state, but allows them
        XCTAssertTrue(address.containsRequiredFields(.full))
        address.postalCode = "ABCDE"
        XCTAssertTrue(address.containsRequiredFields(.full))
        address.state = "Test"
        XCTAssertTrue(address.containsRequiredFields(.full))
    }

    func testContainsRequiredFieldsName() {
        let address = STPAddress()

        XCTAssertFalse(address.containsRequiredFields(.name))
        address.name = "Jane Doe"
        XCTAssertTrue(address.containsRequiredFields(.name))
    }

    func testContainsContentForBillingAddressFields() {
        let address = STPAddress()

        // Empty address should return false for everything
        XCTAssertFalse(address.containsContent(for: .none))
        XCTAssertFalse(address.containsContent(for: .postalCode))
        XCTAssertFalse(address.containsContent(for: .full))
        XCTAssertFalse(address.containsContent(for: .name))

        // 1+ characters in postalCode will return true for .PostalCode && .Full
        address.postalCode = "0"
        XCTAssertFalse(address.containsContent(for: .none))
        XCTAssertTrue(address.containsContent(for: .postalCode))
        XCTAssertTrue(address.containsContent(for: .full))
        // empty string returns false
        address.postalCode = ""
        XCTAssertFalse(address.containsContent(for: .none))
        XCTAssertFalse(address.containsContent(for: .postalCode))
        XCTAssertFalse(address.containsContent(for: .full))
        address.postalCode = nil

        // 1+ characters in name will return true for .Name
        address.name = "Jane Doe"
        XCTAssertTrue(address.containsContent(for: .name))
        // empty string returns false
        address.name = ""
        XCTAssertFalse(address.containsContent(for: .name))
        address.name = nil

        // Test every other property that contributes to the full address, ensuring it returns True for .Full only
        // This is *not* refactoring-safe, but I think it's better than a bunch of duplicated code
        for propertyName in ["line1", "line2", "city", "state", "country"] {
            for testValue in ["a", "0", "Foo Bar"] {
                address.setValue(testValue, forKey: propertyName)
                XCTAssertFalse(address.containsContent(for: .none))
                XCTAssertFalse(address.containsContent(for: .postalCode))
                XCTAssertTrue(address.containsContent(for: .full))
                XCTAssertFalse(address.containsContent(for: .name))
                address.setValue(nil, forKey: propertyName)
            }

            // Make sure that empty string is treated like nil, and returns false for these properties
            address.setValue("", forKey: propertyName)
            XCTAssertFalse(address.containsContent(for: .none))
            XCTAssertFalse(address.containsContent(for: .postalCode))
            XCTAssertFalse(address.containsContent(for: .full))
            XCTAssertFalse(address.containsContent(for: .name))
            address.setValue(nil, forKey: propertyName)
        }

        // ensure it still returns false for everything since it has been cleared
        XCTAssertFalse(address.containsContent(for: .none))
        XCTAssertFalse(address.containsContent(for: .postalCode))
        XCTAssertFalse(address.containsContent(for: .full))
        XCTAssertFalse(address.containsContent(for: .name))
    }

    func testContainsRequiredShippingAddressFields() {
        let address = STPAddress()
        XCTAssertTrue(address.containsRequiredShippingAddressFields(nil))
        let allFields = Set<STPContactField>([
            STPContactField.postalAddress,
            STPContactField.emailAddress,
            STPContactField.phoneNumber,
            STPContactField.name,
        ])
        XCTAssertFalse(address.containsRequiredShippingAddressFields(allFields))

        address.name = "John Smith"
        XCTAssertTrue((address.containsRequiredShippingAddressFields(Set<STPContactField>([STPContactField.name]))))
        XCTAssertFalse((address.containsRequiredShippingAddressFields(Set<STPContactField>([STPContactField.emailAddress]))))

        address.email = "john@example.com"
        XCTAssertTrue((address.containsRequiredShippingAddressFields(Set<STPContactField>([STPContactField.name, STPContactField.emailAddress]))))
        XCTAssertFalse((address.containsRequiredShippingAddressFields(allFields)))

        address.phone = "5555555555"
        XCTAssertTrue((address.containsRequiredShippingAddressFields(Set<STPContactField>([
            STPContactField.name,
            STPContactField.emailAddress,
            STPContactField.phoneNumber,
        ]))))
        address.phone = "555"
        XCTAssertFalse((address.containsRequiredShippingAddressFields(Set<STPContactField>([
            STPContactField.name,
            STPContactField.emailAddress,
            STPContactField.phoneNumber,
        ]))))
        XCTAssertFalse((address.containsRequiredShippingAddressFields(allFields)))
        address.country = "GB"
        XCTAssertTrue((address.containsRequiredShippingAddressFields(Set<STPContactField>([STPContactField.name, STPContactField.emailAddress]))))
        address.phone = "5555555555"
        XCTAssertTrue((address.containsRequiredShippingAddressFields(Set<STPContactField>([
            STPContactField.name,
            STPContactField.emailAddress,
            STPContactField.phoneNumber,
        ]))))

        address.country = "US"
        address.phone = "5555555555"
        address.line1 = "55 John St"
        address.city = "New York"
        address.state = "NY"
        address.postalCode = "12345"
        XCTAssertTrue(address.containsRequiredShippingAddressFields(allFields))
    }

    func testContainsContentForShippingAddressFields() {
        let address = STPAddress()

        // Empty address should return false for everything
        XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))

        // Name
        address.name = "Smith"
        XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))
        address.name = ""

        // Phone
        address.phone = "1"
        XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))
        address.phone = ""

        // Email
        address.email = "f"
        XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))
        address.email = ""

        // Test every property that contributes to the full address
        // This is *not* refactoring-safe, but I think it's better than a bunch more duplicated code
        for propertyName in ["line1", "line2", "city", "state", "postalCode", "country"] {
            for testValue in ["a", "0", "Foo Bar"] {
                address.setValue(testValue, forKey: propertyName)
                XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
                XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
                XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
                XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
                XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))
                address.setValue("", forKey: propertyName)
            }
        }

        // ensure it still returns false for everything with empty strings
        XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))

        // Try a hybrid address, and make sure some bitwise combinations work
        address.name = "a"
        address.phone = "1"
        address.line1 = "_"
        XCTAssertFalse((address.containsContent(forShippingAddressFields: nil)))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name]))))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber]))))
        XCTAssertFalse((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.emailAddress]))))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.postalAddress]))))

        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.name, STPContactField.emailAddress]))))
        XCTAssertTrue((address.containsContent(forShippingAddressFields: Set<STPContactField>([STPContactField.phoneNumber, STPContactField.emailAddress]))))
        XCTAssertTrue(
            (address.containsContent(
                        forShippingAddressFields: Set<STPContactField>([
                            STPContactField.postalAddress,
                            STPContactField.emailAddress,
                            STPContactField.phoneNumber,
                            STPContactField.name,
                        ]))))

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
