//
//  STPLegacyElementsCustomer.swift
//  StripePaymentSheet
//

@_spi(STP) import StripePayments

@_spi(STP) public final class STPLegacyElementsCustomer: NSObject {
    public let payment_methods: [STPPaymentMethod]?

    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPLegacyElementsCustomer.self), self),
            "payment_methods = \(String(describing: payment_methods))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        allResponseFields: [AnyHashable: Any],
        payment_methods: [STPPaymentMethod]?
    ) {
        self.allResponseFields = allResponseFields
        self.payment_methods = payment_methods
        super.init()
    }
}


// MARK: - STPAPIResponseDecodable
extension STPLegacyElementsCustomer: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let paymentMethodPrefDict = dict["legacy_customer"] as? [AnyHashable: Any],
              let savedPaymentMethods = paymentMethodPrefDict["payment_methods"] as? [[AnyHashable: Any]] else {
            return nil
        }
        let paymentMethods = savedPaymentMethods.compactMap { STPPaymentMethod.decodedObject(fromAPIResponse: $0) }
        return STPLegacyElementsCustomer(
            allResponseFields: dict,
            payment_methods: paymentMethods
        ) as? Self
    }
}
