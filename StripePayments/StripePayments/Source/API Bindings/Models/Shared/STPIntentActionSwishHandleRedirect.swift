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
    @objc public let hostedInstructionsURL: URL

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
            "hostedInstructionsURL = \(String(describing: hostedInstructionsURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        hostedInstructionsURL: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.hostedInstructionsURL = hostedInstructionsURL
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
            let hostedInstructionsURLString = dict["hosted_instructions_url"] as? String,
            let hostedInstructionsURL = URL(string: hostedInstructionsURLString)
        else {
            return nil
        }

        return STPIntentActionSwishHandleRedirect(
            hostedInstructionsURL: hostedInstructionsURL,
            allResponseFields: dict
        ) as? Self
    }
}
