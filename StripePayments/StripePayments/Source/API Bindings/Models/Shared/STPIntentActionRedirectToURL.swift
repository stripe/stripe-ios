//
//  STPIntentActionRedirectToURL.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 6/27/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains instructions for authenticating a payment by redirecting your customer to another page or application.
/// You cannot directly instantiate an `STPIntentActionRedirectToURL`.
/// - seealso: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-next_action
public class STPIntentActionRedirectToURL: NSObject {

    /// The URL you must redirect your customer to in order to authenticate the payment.
    @objc public let url: URL
    /// The return URL that'll be redirected back to when the user is done
    /// authenticating.
    @objc public let returnURL: URL?

    /// If true, we'll follow one 30x redirect and open the webview using the resulting URL.
    @_spi(STP) public var followRedirects: Bool {
        return stripeFlagValue("followRedirectsInSDK")
    }

    /// If true, we'll use ASWebAuthenticationSession instead of SFSafariViewController.
    /// Some payment methods benefit from sharing cookies with Safari and
    /// using URL protocol handlers to return to the merchant's app.
    @_spi(STP) public var useWebAuthSession: Bool {
        return stripeFlagValue("useWebAuthSession")
    }

    /// Checks the value of an internal Stripe URL flag, returning `true` if the flag exists and is true, otherwise returning `false`.
    internal func stripeFlagValue(_ flagName: String) -> Bool {
        if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let host = urlComponents.host,
           host.hasSuffix("stripe.com"),
            let queryItems = urlComponents.queryItems,
            let item = queryItems.first(where: { $0.name == flagName }),
           item.value == "true" {
            return true
        }
        return false
    }

    @objc public let allResponseFields: [AnyHashable: Any]

    let threeDSSourceID: String?

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPIntentActionRedirectToURL.self), self),
            // RedirectToURL details (alphabetical)
            "returnURL = \(String(describing: returnURL))",
            "url = \(url)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    init(
        url: URL,
        returnURL: URL?,
        threeDSSourceID: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.url = url
        self.returnURL = returnURL
        self.threeDSSourceID = threeDSSourceID
        self.allResponseFields = allResponseFields
        super.init()
    }

}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionRedirectToURL: STPAPIResponseDecodable {
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let urlString = dict["url"] as? String,
            let url = URL(string: urlString)
        else {
            return nil
        }

        let returnURL: URL?
        if let returnURLString = dict["return_url"] as? String {
            returnURL = URL(string: returnURLString)
        } else {
            returnURL = nil
        }

        return STPIntentActionRedirectToURL(
            url: url,
            returnURL: returnURL,
            threeDSSourceID: url.lastPathComponent.hasPrefix("src_") ? url.lastPathComponent : nil,
            allResponseFields: dict
        ) as? Self
    }
}
