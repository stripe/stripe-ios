//
//  STPPaymentMethodCardArt.swift
//  StripePayments
//
import Foundation

@_spi(STP) public class STPPaymentMethodCardArt: NSObject, STPAPIResponseDecodable {
    @objc public private(set) var artImage: URL
    @objc public private(set) var programName: String
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
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
    required init(artImage: URL, programName: String) {
        self.artImage = artImage
        self.programName = programName
        super.init()
    }
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()

        guard let artImage = dict.stp_string(forKey: "art_image"),
              let artImageURL = URL(string: artImage),
              let programName = dict.stp_string(forKey: "program_name") else {
            return nil
        }
        let cardArt = self.init(artImage: artImageURL, programName: programName)
        cardArt.allResponseFields = response
        return cardArt
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?, hack: String?) -> Self? {
        var url: String
        switch hack {
        case "4242": // visa
            url = "https://b.stripecdn.com/cardart/assets/eNXs6mO6s1JqefGbUN7BEec897N1WiVQn4K1KX-5rao"
        case "4444": // mastercard
            url = "https://b.stripecdn.com/cardart/assets/Myv5rix24rJgZXW7EKyvYBXfGuphYfyIj6dCPljEqPk"
        case "0005": // amex
            url = "https://b.stripecdn.com/cardart/assets/fEEB0jRRjdTPGtGHZbjd7KU87PG4lNVrK8YFRxYH590"
        case "1117": // discover
            url = "https://b.stripecdn.com/cardart/assets/KQiGYOwX1rZE1c7g7sAfwucOnQJdk!8pgY2OP0CBqrU"
        default:
            return nil
        }
        let artImageURL = URL(string: url)!
        let programName = "test"
        let cardArt = self.init(artImage: artImageURL, programName: programName)
        return cardArt
    }
}
