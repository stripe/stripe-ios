//
//  STPIntentActionPromptPayDisplayQrCode.swift
//  StripePayments
//
//  Created by Nick Porter on 9/12/23.
//

import Foundation

/// Contains instructions for presenting the QR code required to complete a PromptPay payment.
/// You cannot directly instantiate an `STPIntentActionPromptPayDisplayQrCode`.
public class STPIntentActionPromptPayDisplayQrCode: NSObject {

    /// The URL to open which contains instructions on how to complete the payment.
    @objc public let hostedInstructionsURL: URL?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(
                format: "%@: %p",
                NSStringFromClass(STPIntentActionPromptPayDisplayQrCode.self),
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
extension STPIntentActionPromptPayDisplayQrCode: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let hostedInstructionsURLString = dict["hosted_instructions_url"] as? String,
            let hostedInstructionsURL = URL(string: hostedInstructionsURLString)
        else {
            return nil
        }

        return STPIntentActionPromptPayDisplayQrCode(
            hostedInstructionsURL: hostedInstructionsURL,
            allResponseFields: dict
        ) as? Self
    }

}
