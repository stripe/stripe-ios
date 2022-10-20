//
//  STPPaymentMethodBillingDetails.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/5/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Billing information associated with a `STPPaymentMethod` that may be used or required by particular types of payment methods.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-billing_details
public class STPPaymentMethodBillingDetails: NSObject, STPAPIResponseDecodable, STPFormEncodable {
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Billing address.
    @objc public var address: STPPaymentMethodAddress?
    /// Email address.
    @objc public var email: String?
    /// Full name.
    @objc public var name: String?
    /// Billing phone number (including extension).
    @objc public var phone: String?
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
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
    @objc public override required init() {
        super.init()
    }

    // MARK: - STPFormEncodable

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter:address)): "address",
            NSStringFromSelector(#selector(getter:email)): "email",
            NSStringFromSelector(#selector(getter:name)): "name",
            NSStringFromSelector(#selector(getter:phone)): "phone",
        ]
    }

    @objc
    public class func rootObjectName() -> String? {
        return nil
    }

    
    // MARK: - NSCopying
    @objc(copyWithZone:) func copy(with zone: NSZone? = nil) -> Any {
        let copyBillingDetails = type(of: self).init()

        copyBillingDetails.allResponseFields = allResponseFields
        copyBillingDetails.address = address?.copy() as? STPPaymentMethodAddress
        copyBillingDetails.email = email
        copyBillingDetails.name = name
        copyBillingDetails.phone = phone

        return copyBillingDetails
    }
    
    static func == (lhs: STPPaymentMethodBillingDetails, rhs: STPPaymentMethodBillingDetails) -> Bool {
        if !((lhs.additionalAPIParameters as NSDictionary).isEqual(to: rhs.additionalAPIParameters))
        {
            return false
        }
        
        return
            lhs.address == rhs.address &&
            lhs.email == rhs.email &&
            lhs.name == rhs.name &&
            lhs.phone == rhs.phone
    }
    
    // MARK: - STPAPIResponseDecodable
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
        let billingDetails = self.init()
        billingDetails.allResponseFields = response
        billingDetails.address = STPPaymentMethodAddress.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "address"))
        billingDetails.email = dict.stp_string(forKey: "email")
        billingDetails.name = dict.stp_string(forKey: "name")
        billingDetails.phone = dict.stp_string(forKey: "phone")
        return billingDetails
    }
}
