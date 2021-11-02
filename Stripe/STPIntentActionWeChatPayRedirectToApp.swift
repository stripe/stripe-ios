//
//  STPIntentActionWechatPayRedirectToApp.swift
//  Stripe
//
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains instructions for authenticating a payment by redirecting your customer to WeChat Pay app.
/// You cannot directly instantiate an `STPIntentActionWechatPayRedirectToApp`.
public class STPIntentActionWechatPayRedirectToApp: NSObject {

    ///
    @objc public let appId: String
    ///
    @objc public let nonceStr: String
    ///
    @objc public let package: String
    ///
    @objc public let partnerId: String
    ///
    @objc public let prepayId: String
    ///
    @objc public let timestamp: Int
    ///
    @objc public let sign: String

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p", NSStringFromClass(STPIntentActionAlipayHandleRedirect.self), self),
            // details
            "appId = \(String(describing: appId))",
            "nonceStr = \(String(describing: nonceStr))",
            "package = \(String(describing: package))",
            "partnerId = \(String(describing: partnerId))",
            "prepayId = \(String(describing: prepayId))",
            "timestamp = \(String(describing: timestamp))",
            "sign = \(String(describing: sign))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        appId: String,
        nonceStr: String,
        package: String,
        partnerId: String,
        prepayId: String,
        timestamp: Int,
        sign: String,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.appId = appId
        self.nonceStr = nonceStr
        self.package = package
        self.partnerId = partnerId
        self.prepayId = prepayId
        self.timestamp = timestamp
        self.sign = sign

        self.allResponseFields = allResponseFields
        
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionWechatPayRedirectToApp: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let appId = dict["app_id"] as? String,
              let nonceStr = dict["nonce_str"] as? String,
              let package = dict["package"] as? String,
              let partnerId = dict["partner_id"] as? String,
              let prepayId = dict["prepay_id"] as? String,
              let timestampString = dict["timestamp"] as? String,
              let timestamp = Int(timestampString),
              let sign = dict["sign"] as? String
        else {
            return nil
        }
        
        return STPIntentActionWechatPayRedirectToApp(
            appId: appId, nonceStr: nonceStr, package: package, partnerId: partnerId, prepayId: prepayId, timestamp: timestamp, sign: sign, allResponseFields: dict) as? Self
    }

}
