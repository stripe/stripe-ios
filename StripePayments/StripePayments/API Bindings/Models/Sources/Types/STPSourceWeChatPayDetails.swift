//
//  STPSourceWeChatPayDetails.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/4/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Details of a WeChat Pay Source.
public class STPSourceWeChatPayDetails: NSObject, STPAPIResponseDecodable {
    /// A URL to the WeChat App.
    /// Use `STPRedirectContext` instead of redirecting users yourself.
    @objc public private(set) var weChatAppURL: String?
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPSourceWeChatPayDetails.self), self),
            "weChatAppURL = \(weChatAppURL ?? "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        let details = self.init()
        details.weChatAppURL = dict.stp_string(forKey: "ios_native_url")
        details.allResponseFields = response
        return details
    }

    override required init() {
        super.init()
    }
}
