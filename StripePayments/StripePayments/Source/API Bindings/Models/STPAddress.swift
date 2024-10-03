//
//  STPAddress.swift
//  StripePayments
//
//  Created by Ben Guo on 4/13/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation
import PassKit
@_spi(STP) import StripeCore

/// STPAddress Contains an address as represented by the Stripe API.
public class STPAddress: NSObject {
    /// The user's full name (e.g. "Jane Doe")
    @objc public var name: String?

    /// The first line of the user's street address (e.g. "123 Fake St")
    @objc public var line1: String?

    /// The apartment, floor number, etc of the user's street address (e.g. "Apartment 1A")
    @objc public var line2: String?

    /// The city in which the user resides (e.g. "San Francisco")
    @objc public var city: String?

    /// The state in which the user resides (e.g. "CA")
    @objc public var state: String?

    /// The postal code in which the user resides (e.g. "90210")
    @objc public var postalCode: String?

    /// The ISO country code of the address (e.g. "US")
    @objc public var country: String?

    /// The phone number of the address (e.g. "8885551212")
    @objc public var phone: String?

    /// The email of the address (e.g. "jane@doe.com")
    @objc public var email: String?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initializes an empty STPAddress.
    @objc
    public override init() {
        super.init()
    }

    /// Initializes a new STPAddress with data from an PassKit contact.
    /// - Parameter contact: The PassKit contact you want to populate the STPAddress from.
    /// - Returns: A new STPAddress instance with data copied from the passed in contact.
    @objc(initWithPKContact:)
    public init(
        pkContact contact: PKContact
    ) {
        super.init()
        let nameComponents = contact.name
        if let nameComponents = nameComponents {
            givenName = stringIfHasContentsElseNil(nameComponents.givenName)
            familyName = stringIfHasContentsElseNil(nameComponents.familyName)

            name = stringIfHasContentsElseNil(
                PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
            )
        }
        email = stringIfHasContentsElseNil(contact.emailAddress)
        if let phoneNumber = contact.phoneNumber {
            phone = sanitizedPhoneString(from: phoneNumber)
        } else {
            phone = nil
        }
        setAddressFromCNPostal(contact.postalAddress)
    }

    /// Initializes a new STPAddress with a contact from the Contacts framework.
    /// - Parameter contact: The CNContact you want to populate the STPAddress from.
    /// - Returns: A new STPAddress instance with data copied from the passed in contact.
    @objc(initWithCNContact:)
    public init(
        cnContact contact: CNContact
    ) {
        super.init()
        givenName = stringIfHasContentsElseNil(contact.givenName)
        familyName = stringIfHasContentsElseNil(contact.familyName)
        name = stringIfHasContentsElseNil(
            CNContactFormatter.string(
                from: contact,
                style: .fullName
            )
        )
        email = stringIfHasContentsElseNil(contact.emailAddresses.first?.value as String?)
        if let value1 = contact.phoneNumbers.first?.value {
            phone = sanitizedPhoneString(from: value1)
        }

        if let value1 = contact.postalAddresses.first?.value {
            setAddressFromCNPostal(value1)
        }
    }

    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]
    private var givenName: String?
    private var familyName: String?

    private func sanitizedPhoneString(from phoneNumber: CNPhoneNumber) -> String? {
        return stringIfHasContentsElseNil(
            STPCardValidator.sanitizedNumericString(for: phoneNumber.stringValue)
        )
    }

    private func setAddressFromCNPostal(_ address: CNPostalAddress?) {
        line1 = stringIfHasContentsElseNil(address?.street)
        city = stringIfHasContentsElseNil(address?.city)
        state = stringIfHasContentsElseNil(address?.state)
        postalCode = stringIfHasContentsElseNil(address?.postalCode)
        country = stringIfHasContentsElseNil(address?.isoCountryCode.uppercased())
    }

}

extension STPAddress: STPAPIResponseDecodable {
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response else {
            return nil
        }

        let address = STPAddress()
        address.allResponseFields = dict
        /// all properties are nullable
        address.city = dict["city"] as? String
        address.country = dict["country"] as? String
        address.line1 = dict["line1"] as? String
        address.line2 = dict["line2"] as? String
        address.postalCode = dict["postal_code"] as? String
        address.state = dict["state"] as? String
        return address as? Self
    }
}

extension STPAddress: STPFormEncodable {

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        // Paralleling `decodedObjectFromAPIResponse:`, *only* the 6 address fields are encoded
        // If this changes, shippingInfoForChargeWithAddress:shippingMethod: might break
        return [
            NSStringFromSelector(#selector(getter: line1)): "line1",
            NSStringFromSelector(#selector(getter: line2)): "line2",
            NSStringFromSelector(#selector(getter: city)): "city",
            NSStringFromSelector(#selector(getter: state)): "state",
            NSStringFromSelector(#selector(getter: CNMutablePostalAddress.postalCode)):
                "postal_code",
            NSStringFromSelector(#selector(getter: country)): "country",
        ]
    }

}

extension STPAddress: NSCopying {
    /// :nodoc:
    @objc
    public func copy(with zone: NSZone? = nil) -> Any {
        let copyAddress = STPAddress()

        // Name might be stored as full name in _name, or split between given/family name
        // access ivars directly and explicitly copy the instances.
        copyAddress.name = name
        copyAddress.givenName = givenName
        copyAddress.familyName = familyName

        copyAddress.line1 = line1
        copyAddress.line2 = line2
        copyAddress.city = city
        copyAddress.state = state
        copyAddress.postalCode = postalCode
        copyAddress.country = country

        copyAddress.phone = phone
        copyAddress.email = email

        copyAddress.allResponseFields = allResponseFields

        return copyAddress
    }
}
