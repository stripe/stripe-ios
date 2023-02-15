//
//  STPElementsSession.swift
//  StripePayments
//
//  Created by Nick Porter on 2/15/23.
//

import Foundation

public class STPElementsSession: NSObject {
    
    /// The list of payment method types (e.g. `[NSNumber(value: STPPaymentMethodType.card.rawValue)]`) that this PaymentIntent is allowed to use.
    @objc public let paymentMethodTypes: [NSNumber]
    
    /// The ordered payment method preference for this PaymentIntent
    @_spi(STP) public let orderedPaymentMethodTypes: [STPPaymentMethodType]

    /// A list of payment method types that are not activated in live mode, but activated in test mode
    @_spi(STP) public let unactivatedPaymentMethodTypes: [STPPaymentMethodType]
    
    /// Link-specific settings for this PaymentIntent.
    @_spi(STP) public let linkSettings: LinkSettings?

    /// Country code of the user.
    @_spi(STP) public let countryCode: String?
    
    @objc public let allResponseFields: [AnyHashable: Any]
    
    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPElementsSession.self), self),
            "paymentMethodTypes = \(String(describing: paymentMethodTypes))",
            "orderedPaymentMethodTypes = \(String(describing: orderedPaymentMethodTypes))",
            "unactivatedPaymentMethodTypes = \(String(describing: unactivatedPaymentMethodTypes))",
            "linkSettings = \(String(describing: linkSettings))",
            "countryCode = \(String(describing: countryCode))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
    
    private init(
        allResponseFields: [AnyHashable: Any],
        paymentMethodTypes: [NSNumber],
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType],
        countryCode: String?,
        linkSettings: LinkSettings?
    ) {
        self.allResponseFields = allResponseFields
        self.countryCode = countryCode
        self.linkSettings = linkSettings
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.paymentMethodTypes = paymentMethodTypes
        self.unactivatedPaymentMethodTypes = unactivatedPaymentMethodTypes
        super.init()
    }
}

// MARK: - STPAPIResponseDecodable
extension STPElementsSession: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let dict = response,
              let paymentMethodPrefDict = dict["payment_method_preference"] as? [AnyHashable: Any],
              let paymentMethodTypeStrings = dict["payment_method_types"] as? [String]
        else {
            return nil
        }
        
        return STPElementsSession(allResponseFields: dict,
                                  paymentMethodTypes: STPPaymentMethod.types(from: paymentMethodTypeStrings),
                                  orderedPaymentMethodTypes: STPPaymentMethod.paymentMethodTypes(
                                    from: paymentMethodPrefDict["ordered_payment_method_types"] as? [String] ?? paymentMethodTypeStrings
                                  ),
                                  unactivatedPaymentMethodTypes: STPPaymentMethod.paymentMethodTypes(
                                    from: dict["unactivated_payment_method_types"] as? [String] ?? []
                                  ),
                                  countryCode: paymentMethodPrefDict["country_code"] as? String,
                                  linkSettings: LinkSettings.decodedObject(
                                    fromAPIResponse: dict["link_settings"] as? [AnyHashable: Any]
                                )) as? Self
    }
    
    
}
