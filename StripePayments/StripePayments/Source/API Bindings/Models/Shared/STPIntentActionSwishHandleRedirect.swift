//
//  STPIntentActionSwishHandleRedirect.swift
//  StripePayments
//
//  Created by Eduardo Urias on 9/20/23.
//

import Foundation

/// Contains instructions for redirecting to the Swish app.
/// You cannot directly instantiate an `STPIntentActionSwishHandle`.
public class STPIntentActionSwishHandleRedirect: NSObject {

    /// The native URL you must redirect your customer to in order to authenticate the payment.
    @objc public let hostedInstructionsUrl: URL

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPIntentActionSwishHandleRedirect.self),
                self
            ),
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
extension STPIntentActionSwishHandleRedirect: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard
            let dict = response,
            let mobileAuthURLString = dict["mobile_auth_url"] as? String,
            let hostedInstructionsUrl = URL(string: mobileAuthURLString)
        else {
            return nil
        }

        return STPIntentActionSwishHandleRedirect(
            hostedInstructionsUrl: hostedInstructionsUrl,
            allResponseFields: dict
        ) as? Self
    }
}
