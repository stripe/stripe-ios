//
//  STPPaymentMethodShopPay.swift
//  StripePayments
//

import Foundation
/// ShopPay Payment Method.
@_spi(STP) public class STPPaymentMethodShopPay: NSObject, STPAPIResponseDecodable {
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]

    /// Associated external source Id
    @objc public private(set) var externalSourceId: String

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodShopPay.self), self),
            "externalSourceId = \(externalSourceId)",
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
        guard let externalSourceId = dict.stp_string(forKey: "external_source_id") else {
            return nil
        }

        self.externalSourceId = externalSourceId

        super.init()
        allResponseFields = dict
    }
}
