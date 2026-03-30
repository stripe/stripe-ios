//
//  STPPaymentMethodCardArt.swift
//  StripePayments
//
import Foundation

@_spi(STP) public class STPPaymentMethodCardArt: NSObject, STPAPIResponseDecodable {
    public private(set) var paymentMethod: String
    public private(set) var artImage: URL?
    public private(set) var programName: String?
    public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardArt.self), self),
            // Properties
            "artImage: \(String(describing: artImage))",
            "programName: \(String(describing: programName))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    required init(paymentMethod: String, artImage: URL?, programName: String?) {
        self.paymentMethod = paymentMethod
        self.artImage = artImage
        self.programName = programName
        super.init()
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        guard let paymentMethod = dict.stp_string(forKey: "payment_method") else {
            return nil
        }

        let artImageDict = dict["art_image"] as? [AnyHashable: Any]
        let artImageString = artImageDict?.stp_string(forKey: "url") ?? ""
        let artImage = artImageString.isEmpty ? nil : URL(string: artImageString)
        let programName = dict.stp_string(forKey: "program_name")
        let cardArt = self.init(paymentMethod: paymentMethod, artImage: artImage, programName: programName)

        cardArt.allResponseFields = response
        return cardArt
    }
}
