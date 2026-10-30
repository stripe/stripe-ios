//
//  STPPaymentMethodAddress.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Contacts
import Foundation

/// The billing address, a property on `STPPaymentMethodBillingDetails`
public class STPPaymentMethodAddress: NSObject, STPAPIResponseDecodable, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// City/District/Suburb/Town/Village.
    public var city: String?
    /// 2-letter country code.
    public var country: String?
    /// Address line 1 (Street address/PO Box/Company name).
    public var line1: String?
    /// Address line 2 (Apartment/Suite/Unit/Building).
    public var line2: String?
    /// ZIP or postal code.
    public var postalCode: String?
    /// State/County/Province/Region.
    public var state: String?

    /// Convenience initializer for creating a STPPaymentMethodAddress from an STPAddress.
    public init(
        address: STPAddress
    ) {
        super.init()
        city = address.city
        country = address.country
        line1 = address.line1
        line2 = address.line2
        postalCode = address.postalCode
        state = address.state
    }

    /// :nodoc:
    public required override init() {
        super.init()
    }

    /// :nodoc:
    private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodAddress.self), self),
            // Properties
            "line1 = \(line1 ?? "")",
            "line2 = \(line2 ?? "")",
            "city = \(city ?? "")",
            "state = \(state ?? "")",
            "postalCode = \(postalCode ?? "")",
            "country = \(country ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodAddress.line1: "line1",
            \STPPaymentMethodAddress.line2: "line2",
            \STPPaymentMethodAddress.city: "city",
            \STPPaymentMethodAddress.country: "country",
            \STPPaymentMethodAddress.state: "state",
            \STPPaymentMethodAddress.postalCode:
                "postal_code",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }

    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copyPaymentMethodAddress = type(of: self).init()

        copyPaymentMethodAddress.allResponseFields = allResponseFields
        copyPaymentMethodAddress.city = city
        copyPaymentMethodAddress.country = country
        copyPaymentMethodAddress.line1 = line1
        copyPaymentMethodAddress.line2 = line2
        copyPaymentMethodAddress.postalCode = postalCode
        copyPaymentMethodAddress.state = state
        return copyPaymentMethodAddress
    }

    // MARK: - Equality
    /// :nodoc:
    public override func isEqual(_ other: Any?) -> Bool {
        return isEqual(to: other as? STPPaymentMethodAddress)
    }

    func isEqual(to other: STPPaymentMethodAddress?) -> Bool {
        if self === other {
            return true
        }

        guard let other = other else {
            return false
        }

        if !((additionalAPIParameters as NSDictionary).isEqual(to: other.additionalAPIParameters)) {
            return false
        }

        return city == other.city && country == other.country && line1 == other.line1
            && line2 == other.line2 && postalCode == other.postalCode && state == other.state
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        let address = self.init()
        address.allResponseFields = response
        address.city = dict.stp_string(forKey: "city")
        address.country = dict.stp_string(forKey: "country")
        address.line1 = dict.stp_string(forKey: "line1")
        address.line2 = dict.stp_string(forKey: "line2")
        address.postalCode = dict.stp_string(forKey: "postal_code")
        address.state = dict.stp_string(forKey: "state")
        return address
    }
}
