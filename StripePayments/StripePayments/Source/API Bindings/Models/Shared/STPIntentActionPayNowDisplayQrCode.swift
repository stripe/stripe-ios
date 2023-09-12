//
//  STPIntentActionPayNowDisplayQrCode.swift
//  StripePayments
//
//  Created by Nick Porter on 9/7/23.
//

import Foundation

/// Contains instructions for presenting the QR code required to complete a PayNow payment.
/// You cannot directly instantiate an `STPIntentActionPayNowDisplayQrCode`.
public class STPIntentActionPayNowDisplayQrCode: NSObject {

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
                NSStringFromClass(STPIntentActionPayNowDisplayQrCode.self),
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
extension STPIntentActionPayNowDisplayQrCode: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let hostedInstructionsURLString = dict["hosted_instructions_url"] as? String,
            let hostedInstructionsURL = URL(string: hostedInstructionsURLString)
        else {
            return nil
        }

        return STPIntentActionPayNowDisplayQrCode(
            hostedInstructionsURL: hostedInstructionsURL,
            allResponseFields: dict
        ) as? Self
    }

}
