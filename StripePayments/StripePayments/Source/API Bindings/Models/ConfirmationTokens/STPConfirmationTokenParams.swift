//
//  STPConfirmationTokenParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/2/25.
//

import Foundation

/// An object representing parameters used to create a ConfirmationToken object.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
@_spi(STP) public class STPConfirmationTokenParams: NSObject, STPFormEncodable {
    private var _additionalAPIParameters: [AnyHashable: Any] = [:]

    /// ID of an existing PaymentMethod to use for this ConfirmationToken.
    @objc public var paymentMethod: String?

    /// Payment method details for the ConfirmationToken.
    @objc public var paymentMethodData: STPPaymentMethodParams?

    /// Payment-method-specific configuration for this ConfirmationToken.
    @objc public var paymentMethodOptions: STPPaymentMethodOptions?

    /// Return URL to redirect the customer back to your application after completion of 3D Secure authentication.
    @objc public var returnURL: String?

    /// Indicates that you intend to make future payments with the payment method collected during checkout.
    @objc public var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none

    /// Shipping information to include with the ConfirmationToken.
    @objc public var shipping: STPPaymentIntentShippingDetailsParams?

    /// Details about the Mandate to create.
    @objc public var mandateData: STPMandateDataParams?

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenParams.self), self),
            // ConfirmationTokenParams details
            "paymentMethod = \(paymentMethod ?? "")",
            "paymentMethodData = \(String(describing: paymentMethodData))",
            "paymentMethodOptions = \(String(describing: paymentMethodOptions))",
            "returnURL = \(returnURL ?? "")",
            "setupFutureUsage = \(String(describing: setupFutureUsage))",
            "shipping = \(String(describing: shipping))",
            "mandateData = \(String(describing: mandateData))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPFormEncodable

    @objc
    public static func rootObjectName() -> String? {
        return nil
    }

    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: paymentMethod)): "payment_method",
            NSStringFromSelector(#selector(getter: paymentMethodData)): "payment_method_data",
            NSStringFromSelector(#selector(getter: paymentMethodOptions)): "payment_method_options",
            NSStringFromSelector(#selector(getter: returnURL)): "return_url",
            NSStringFromSelector(#selector(getter: shipping)): "shipping",
            NSStringFromSelector(#selector(getter: mandateData)): "mandate_data",
        ]
    }

    @objc public var additionalAPIParameters: [AnyHashable: Any] {
        get {
            var params = _additionalAPIParameters
            // Only include setup_future_usage if it has a valid string value (not .none or .unknown)
            if let stringValue = setupFutureUsage.stringValue {
                params["setup_future_usage"] = stringValue
            }
            return params
        }
        set {
            _additionalAPIParameters = newValue
        }
    }
}
