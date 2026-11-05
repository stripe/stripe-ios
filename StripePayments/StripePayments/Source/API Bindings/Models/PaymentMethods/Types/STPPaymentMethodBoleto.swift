//
//  STPPaymentMethodBoleto.swift
//  StripePayments
//
//  Created by Ramon Torres on 9/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// A Boleto Payment Method.
/// - seealso: https://stripe.com/docs/payments/boleto
public class STPPaymentMethodBoleto: NSObject, STPAPIResponseDecodable {

    /// The tax ID of the customer (CPF for individuals or CNPJ for businesses).
    public let taxID: String

    /// :nodoc:
    public let allResponseFields: [AnyHashable: Any]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBoleto.self), self),
            // Properties
            "taxID: <redacted>",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPAPIResponseDecodable

    required init?(
        dictionary: [AnyHashable: Any]
    ) {
        guard let taxID = dictionary["tax_id"] as? String else {
            return nil
        }

        self.taxID = taxID
        self.allResponseFields = dictionary

        super.init()
    }

    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        return self.init(dictionary: response)
    }
}
