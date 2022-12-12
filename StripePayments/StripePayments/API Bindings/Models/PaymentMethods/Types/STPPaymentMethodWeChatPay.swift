//
//  STPPaymentMethodWeChatPay.swift
//  StripePayments
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// A WeChat Pay Payment Method.
/// - seealso: https://stripe.com/docs/api/payment_methods/object#payment_method_object-wechat_pay
/// WeChat Pay is currently unavailable in the iOS SDK.
class STPPaymentMethodWeChatPay: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodWeChatPay.self), self)
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        return self.init(dictionary: response)
    }

    required init?(
        dictionary dict: [AnyHashable: Any]
    ) {
        super.init()
        allResponseFields = dict
    }
}
