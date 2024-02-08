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
    @objc public let hostedInstructionsUrl: URL?

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
            "hostedInstructionsUrl = \(String(describing: hostedInstructionsUrl))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        hostedInstructionsUrl: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.hostedInstructionsUrl = hostedInstructionsUrl
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionCashAppRedirectToApp: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let mobileAuthURLString = dict["hosted_instructions_url"] as? String,
            let hostedInstructionsUrl = URL(string: mobileAuthURLString)
        else {
            return nil
        }

        return STPIntentActionCashAppRedirectToApp(
            hostedInstructionsUrl: hostedInstructionsUrl,
            allResponseFields: dict
        ) as? Self
    }

}
