//
//  STPConfirmLinkOptions.swift
//  StripePayments
//
//  Created by Till Hellmund on 4/26/25.
//

import Foundation

// MARK: - STPConfirmLinkOptions
/// Options to update a Link PaymentMethod during PaymentIntent confirmation.
@_spi(STP) public class STPConfirmLinkOptions: NSObject {
    /// Indicates that you intend to make future payments with this payment method.
    /// Providing this parameter will attach the payment method to the PaymentIntent’s Customer, if present, after the Intent is confirmed and any required actions from the user are complete. If no Customer was provided, the payment method can still be attached to a Customer after the transaction completes.
    ///
    /// If setup_future_usage is already set, you may only update the value from on_session to off_session.
    @objc public var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
}

// MARK: - STPFormEncodable
extension STPConfirmLinkOptions: STPFormEncodable {

    @objc internal var setupFutureUsageRawString: String? {
        return setupFutureUsage.stringValue
    }

    public static func rootObjectName() -> String? {
        return "link"
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        [NSStringFromSelector(#selector(getter: setupFutureUsageRawString)): "setup_future_usage"]
    }
}
