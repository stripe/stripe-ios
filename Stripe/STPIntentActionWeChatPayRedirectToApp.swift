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

    /// The native URL you must redirect your customer to in order to authenticate the payment.
    @objc public let nativeURL: URL?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p", NSStringFromClass(STPIntentActionAlipayHandleRedirect.self), self),
            // RedirectToURL details (alphabetical)
            "nativeURL = \(String(describing: nativeURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        nativeURL: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
//        self.nativeURL = nativeURL
        self.allResponseFields = allResponseFields
        
        // TODO: HACK, Until we fix this server-side, reformat the URL to the new universal links style
        var newURLString = nativeURL.absoluteString
        let bundleID = Bundle.main.bundleIdentifier!
        newURLString = newURLString.replacingOccurrences(of: "weixin://app/", with: "https://help.wechat.com/app/")
        newURLString = newURLString.appending("&wechat_app_bundleId=\(bundleID)")

        
        self.nativeURL = URL(string: newURLString)
        
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionWechatPayRedirectToApp: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let nativeURLString = dict["native_url"] as? String,
            let nativeURL = URL(string: nativeURLString)
        else {
            return nil
        }
        
        return STPIntentActionWechatPayRedirectToApp(
            nativeURL: nativeURL,
            allResponseFields: dict) as? Self
    }

}
