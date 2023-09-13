//
//  STPElementsCustomerError.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

final class STPElementsCustomerError: NSObject, Error {
    let errorMessage: String

    let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPElementsCustomerError.self), self),
            "errorMessage = \(errorMessage)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        errorMessage: String
    ) {
        self.allResponseFields = allResponseFields
        self.errorMessage = errorMessage
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
            errorMessage: paymentMethodPrefDict["error_message"] as? String ?? ""
        ) as? Self
    }
}
