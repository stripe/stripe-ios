//
//  STPIntentActionCashAppRedirectToApp.swift
//  StripePayments
//
//  Created by Nick Porter on 12/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Contains instructions for authenticating a payment by redirecting your customer to Cash App.
/// You cannot directly instantiate an `STPIntentActionCashAppRedirectToApp`.
public class STPIntentActionCashAppRedirectToApp: NSObject {

    /// The native URL you must redirect your customer to in order to authenticate the payment.
    @objc public let mobileAuthURL: URL?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPIntentActionCashAppRedirectToApp.self),
                self
            ),
            // RedirectToURL details (alphabetical)
            "mobileAuthURL = \(String(describing: mobileAuthURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        mobileAuthURL: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.mobileAuthURL = mobileAuthURL
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionCashAppRedirectToApp: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let mobileAuthURLString = dict["mobile_auth_url"] as? String,
            let mobileAuthURL = URL(string: mobileAuthURLString)
        else {
            return nil
        }

        return STPIntentActionCashAppRedirectToApp(
            mobileAuthURL: mobileAuthURL,
            allResponseFields: dict
        ) as? Self
    }

}
