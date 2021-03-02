//
//  STPPaymentMethodCardWalletMasterpass.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 3/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Masterpass Card Wallet
/// - seealso: https://stripe.com/docs/masterpass
public class STPPaymentMethodCardWalletMasterpass: NSObject, STPAPIResponseDecodable {
    /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
    @objc public private(set) var email: String?
    /// Owner’s verified email. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
    @objc public private(set) var name: String?
    /// Owner’s verified billing address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
    @objc public private(set) var billingAddress: STPPaymentMethodAddress?
    /// Owner’s verified shipping address. Values are verified or provided by the payment method directly (and if supported) at the time of authorization or settlement.
    @objc public private(set) var shippingAddress: STPPaymentMethodAddress?
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(
                format: "%@: %p", NSStringFromClass(STPPaymentMethodCardWalletMasterpass.self), self
            ),
            // Properties
            "email: \(email ?? "")",
            "name: \(name ?? "")",
            "billingAddress: \(String(describing: billingAddress))",
            "shippingAddress: \(String(describing: shippingAddress))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable

    override required init() {
        super.init()
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = (response as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary

        let masterpass = self.init()
        masterpass.allResponseFields = response
        masterpass.billingAddress = STPPaymentMethodAddress.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "billing_address"))
        masterpass.shippingAddress = STPPaymentMethodAddress.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "shipping_address"))
        masterpass.email = dict.stp_string(forKey: "email")
        masterpass.name = dict.stp_string(forKey: "name")
        return masterpass
    }
}
