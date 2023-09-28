//
//  STPConfirmKonbiniOptions.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 9/12/23.
//

import Foundation

/// Options for a Konbini Payment Methods during PaymentIntent confirmation
/// - seealso https://stripe.com/docs/api/errors#errors-payment_intent-payment_method_options-konbini
@objc public class STPConfirmKonbiniOptions: NSObject {
    /// An optional 10 to 11 digit numeric-only string determining the confirmation code at applicable convenience stores.
    @objc public var confirmationNumber: String?
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

// MARK: - STPFormEncodable
extension STPConfirmKonbiniOptions: STPFormEncodable {
    public static func rootObjectName() -> String? {
        return "konbini"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        [NSStringFromSelector(#selector(getter: confirmationNumber)): "confirmation_number"]
    }
}
