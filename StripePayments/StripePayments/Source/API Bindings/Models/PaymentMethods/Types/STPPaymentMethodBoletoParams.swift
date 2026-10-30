//
//  STPPaymentMethodBoletoParams.swift
//  StripePayments
//
//  Created by Ramon Torres on 9/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An object representing parameters used to create a Boleto Payment Method
public class STPPaymentMethodBoletoParams: NSObject, STPFormEncodable {

    /// The tax ID of the customer (CPF for individuals or CNPJ for businesses).
    ///
    /// Supported formats:
    /// * `XXX.XXX.XXX-XX` or `XXXXXXXXXXX` for CPF
    /// * `XX.XXX.XXX/XXXX-XX` or `XXXXXXXXXXXXXX` for CNPJ
    @objc public var taxID: String?

    /// :nodoc:
    public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// :nodoc:
    public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPPaymentMethodBoletoParams.self), self),
            // Properties
            "taxID: \(taxID != nil ? "<redacted>" : "")",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    public class func rootObjectName() -> String? {
        return "boleto"
    }

    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: taxID)): "tax_id"
        ]
    }
}
