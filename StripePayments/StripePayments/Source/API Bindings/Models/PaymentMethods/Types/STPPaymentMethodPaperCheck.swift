//
//  STPPaymentMethodPaperCheck.swift
//  StripePayments
//
//  Created by Martin Gordon on 8/7/25.
//

import Foundation
/// Paper Check Payment Method.
@_spi(STP) public class STPPaymentMethodPaperCheck: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// Associated US Paper Check token
    @objc public private(set) var token: String

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodShopPay.self), self),
            "token = \(token)",
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

    required init?(dictionary dict: [AnyHashable: Any]) {
        guard let token = dict.stp_string(forKey: "token") else {
            return nil
        }

        self.token = token

        super.init()
        allResponseFields = dict
    }
}
