//
//  STPPaymentMethodCardArt.swift
//  StripePayments
//
import Foundation

@_spi(STP) public class STPPaymentMethodCardArt: NSObject, STPAPIResponseDecodable {
    @objc public private(set) var paymentMethod: String
    @objc public private(set) var url: URL?
    @objc public private(set) var programName: String?
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodCardArt.self), self),
            // Properties
            "url: \(String(describing: url))",
            "programName: \(String(describing: programName))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable
    required init(paymentMethod: String, url: URL?, programName: String?) {
        self.paymentMethod = paymentMethod
        self.url = url
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

        let urlString = dict.stp_string(forKey: "url") ?? ""
        let url = URL(string: urlString)
        let programName = dict.stp_string(forKey: "program_name")
        let cardArt = self.init(paymentMethod: paymentMethod, url: url, programName: programName)

        cardArt.allResponseFields = response
        return cardArt
    }
}
