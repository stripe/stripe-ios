//
//  STPElementsCustomerError.swift
//  StripePaymentSheet
//

@_spi(STP) import StripePayments

@_spi(STP) public final class STPElementsCustomerError: NSObject, Error {
    public let error_message: String

    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPElementsCustomerError.self), self),
            "error_message = \(error_message)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        error_message: String
    ) {
        self.allResponseFields = allResponseFields
        self.error_message = error_message
        super.init()
    }
}


// MARK: - STPAPIResponseDecodable
extension STPElementsCustomerError: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let paymentMethodPrefDict = dict["customer_error"] as? [AnyHashable: Any] else {
            return nil
        }

        return STPElementsCustomerError(
            allResponseFields: dict,
            error_message: paymentMethodPrefDict["error_message"] as? String ?? ""
        ) as? Self
    }
}
