//
//  STPIntentActionRedirectToURL.swift
//  Stripe
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
            allResponseFields: dict) as? Self
    }
}
