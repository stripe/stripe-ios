//
//  STPPaymentMethodBillingDetails.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// Billing information associated with a `STPPaymentMethod` that may be used or required by particular types of payment methods.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-billing_details
public class STPPaymentMethodBillingDetails: NSObject, STPAPIResponseDecodable, STPFormEncodable {
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Billing address.
    public var address: STPPaymentMethodAddress?
    /// Email address.
    public var email: String?
    /// Full name.
    public var name: String?
    /// Billing phone number (including extension).
    public var phone: String?
    public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBillingDetails.self), self),
            // Properties
            "name = \(name ?? "")",
            "phone = \(phone ?? "")",
            "email = \(email ?? "")",
            "address = \(String(describing: address))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    /// :nodoc:
    public override required init() {
        super.init()
    }

    // MARK: - STPFormEncodable

    public class func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPPaymentMethodBillingDetails.address: "address",
            \STPPaymentMethodBillingDetails.email: "email",
            \STPPaymentMethodBillingDetails.name: "name",
            \STPPaymentMethodBillingDetails.phone: "phone",
        ]
    }

    public class func rootObjectName() -> String? {
        return nil
    }

    // MARK: - NSCopying
    func copy(with zone: NSZone? = nil) -> Any {
        let copyBillingDetails = type(of: self).init()

        copyBillingDetails.allResponseFields = allResponseFields
        copyBillingDetails.address = address?.copy() as? STPPaymentMethodAddress
        copyBillingDetails.email = email
        copyBillingDetails.name = name
        copyBillingDetails.phone = phone

        return copyBillingDetails
    }

    // MARK: - Equality
    /// :nodoc:
    public override func isEqual(_ other: Any?) -> Bool {
        return isEqual(to: other as? STPPaymentMethodBillingDetails)
    }

    func isEqual(to other: STPPaymentMethodBillingDetails?) -> Bool {
        if self === other {
            return true
        }

        guard let other = other else {
            return false
        }

        if !((additionalAPIParameters as NSDictionary).isEqual(to: other.additionalAPIParameters)) {
            return false
        }

        return
            address == other.address && email == other.email && name == other.name
            && phone == other.phone
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        let billingDetails = self.init()
        billingDetails.allResponseFields = response
        billingDetails.address = STPPaymentMethodAddress.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "address")
        )
        billingDetails.email = dict.stp_string(forKey: "email")
        billingDetails.name = dict.stp_string(forKey: "name")
        billingDetails.phone = dict.stp_string(forKey: "phone")
        return billingDetails
    }
}

/// :nodoc:
extension STPPaymentMethodBillingDetails {
    /// Convenience initializer for creating an `STPPaymentMethodBillingDetails` instance with a postal and country code
    convenience init(
        postalCode: String,
        countryCode: String? = Locale.autoupdatingCurrent.stp_regionCode
    ) {
        self.init()
        let address = STPPaymentMethodAddress()
        address.postalCode = postalCode
        address.country = countryCode
        self.address = address
    }

    /// Convenience initializer for creating an `STPPaymentMethodBillingDetails` instance with a Link BillingDetails
    @_spi(InternalOnlyAPI) public convenience init?(
        billingAddress: BillingAddress?,
        email: String?
    ) {
        self.init()
        let address = STPPaymentMethodAddress()
        address.line1 = billingAddress?.line1
        address.line2 = billingAddress?.line2
        address.city = billingAddress?.city
        address.state = billingAddress?.state
        address.postalCode = billingAddress?.postalCode
        address.country = billingAddress?.countryCode
        self.address = address
        self.name = billingAddress?.name
        self.email = email
    }
}
