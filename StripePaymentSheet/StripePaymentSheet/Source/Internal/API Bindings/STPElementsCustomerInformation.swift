//
//  STPElementsCustomerInformation.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripePayments

final class STPElementsCustomerInformation: NSObject {
    let paymentMethods: [STPPaymentMethod]

    let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(STPElementsCustomerInformation.self), self),
            "paymentMethods = \(String(describing: paymentMethods))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        paymentMethods: [STPPaymentMethod]
    ) {
        self.allResponseFields = allResponseFields
        self.paymentMethods = paymentMethods
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPElementsCustomerInformation: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let paymentMethodPrefDict = dict["legacy_customer"] as? [AnyHashable: Any],
              let savedPaymentMethods = paymentMethodPrefDict["payment_methods"] as? [[AnyHashable: Any]] else {
            return nil
        }
        let paymentMethods = savedPaymentMethods.compactMap { STPPaymentMethod.decodedObject(fromAPIResponse: $0) }
        return STPElementsCustomerInformation(
            allResponseFields: dict,
            paymentMethods: paymentMethods
        ) as? Self
    }
}
