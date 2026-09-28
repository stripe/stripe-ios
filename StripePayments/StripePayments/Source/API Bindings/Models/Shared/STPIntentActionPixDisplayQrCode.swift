//
//  STPIntentActionPixDisplayQrCode.swift
//  StripePayments
//

import Foundation

/// Contains the QR code and hosted instructions required to complete a Pix payment.
/// You cannot directly instantiate an `STPIntentActionPixDisplayQrCode`.
public class STPIntentActionPixDisplayQrCode: NSObject {

    /// The Pix copy-and-paste string represented by the QR code.
    @objc public let data: String?

    /// A PNG image containing the Pix QR code.
    @objc public let imageURLPNG: URL?

    /// An SVG image containing the Pix QR code.
    @objc public let imageURLSVG: URL?

    /// The time at which the Pix QR code expires.
    @objc public let expiresAt: Date?

    /// The URL to open which contains instructions on how to complete the payment.
    @objc public let hostedInstructionsURL: URL?

    /// :nodoc:
    @objc public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            String(
                format: "%@: %p",
                NSStringFromClass(STPIntentActionPixDisplayQrCode.self),
                self
            ),
            "data = \(data != nil ? "<redacted>" : "nil")",
            "imageURLPNG = \(String(describing: imageURLPNG))",
            "imageURLSVG = \(String(describing: imageURLSVG))",
            "expiresAt = \(String(describing: expiresAt))",
            "hostedInstructionsURL = \(String(describing: hostedInstructionsURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    internal init(
        data: String?,
        imageURLPNG: URL?,
        imageURLSVG: URL?,
        expiresAt: Date?,
        hostedInstructionsURL: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.data = data
        self.imageURLPNG = imageURLPNG
        self.imageURLSVG = imageURLSVG
        self.expiresAt = expiresAt
        self.hostedInstructionsURL = hostedInstructionsURL
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPIntentActionPixDisplayQrCode: STPAPIResponseDecodable {

    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let hostedInstructionsURLString = dict["hosted_instructions_url"] as? String,
              let hostedInstructionsURL = URL(string: hostedInstructionsURLString)
        else {
            return nil
        }

        let expiresAt = (dict["expires_at"] as? NSNumber).map {
            Date(timeIntervalSince1970: $0.doubleValue)
        }
        return STPIntentActionPixDisplayQrCode(
            data: dict["data"] as? String,
            imageURLPNG: (dict["image_url_png"] as? String).flatMap(URL.init(string:)),
            imageURLSVG: (dict["image_url_svg"] as? String).flatMap(URL.init(string:)),
            expiresAt: expiresAt,
            hostedInstructionsURL: hostedInstructionsURL,
            allResponseFields: dict
        ) as? Self
    }
}
