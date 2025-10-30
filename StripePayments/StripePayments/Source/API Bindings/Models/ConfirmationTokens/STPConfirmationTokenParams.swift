//
//  STPConfirmationTokenParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/2/25.
//

import Foundation
@_spi(STP) import StripeCore

/// An object representing parameters used to create a ConfirmationToken object.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
@_spi(STP) public class STPConfirmationTokenParams: NSObject, STPFormEncodable {
    private var _additionalAPIParameters: [AnyHashable: Any] = [:]

    /// ID of an existing PaymentMethod to use for this ConfirmationToken.
    @objc public var paymentMethod: String?

    /// Payment method details for the ConfirmationToken.
    @objc public var paymentMethodData: STPPaymentMethodParams?

    /// Payment-method-specific configuration for this ConfirmationToken.
    @objc public var paymentMethodOptions: STPConfirmPaymentMethodOptions?

    /// Return URL to redirect the customer back to your application after completion of 3D Secure authentication.
    @objc public var returnURL: String?

    /// Indicates that you intend to make future payments with the payment method collected during checkout.
    @objc public var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none

    /// Shipping information to include with the ConfirmationToken.
    @objc public var shipping: STPPaymentIntentShippingDetailsParams?

    /// Details about the Mandate to create.
    @objc public var mandateData: STPMandateDataParams?

    /// `@YES` to set this ConfirmationToken's PaymentMethod as the associated Customer's default
    /// This should be a boolean NSNumber, so that it can be `nil`
    @objc @_spi(STP) public var setAsDefaultPM: NSNumber?

    /// Contains metadata with identifiers for the session and information about the integration
    @objc @_spi(STP) public var clientAttributionMetadata: STPClientAttributionMetadata?

    /// Client context for the ConfirmationToken, containing information about the payment flow context
    @objc @_spi(STP) public var clientContext: STPConfirmationTokenClientContext?

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
            "setAsDefaultPM = \(String(describing: setAsDefaultPM))",
            "clientAttributionMetadata = \(String(describing: clientAttributionMetadata))",
            "clientContext = \(String(describing: clientContext))",
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
            NSStringFromSelector(#selector(getter: setAsDefaultPM)): "set_as_default_payment_method",
            NSStringFromSelector(#selector(getter: clientAttributionMetadata)): "client_attribution_metadata",
            NSStringFromSelector(#selector(getter: clientContext)): "client_context",
        ]
    }

    @objc public var additionalAPIParameters: [AnyHashable: Any] {
        get {
            var params = _additionalAPIParameters
            // Only include setup_future_usage if it has a valid string value (not .none or .unknown)
            if let stringValue = setupFutureUsage.stringValue {
                params["setup_future_usage"] = stringValue
            }
            // Only include set_as_default_payment_method if it has a value
            if let setAsDefault = setAsDefaultPM {
                params["set_as_default_payment_method"] = setAsDefault
            }
            return params
        }
        set {
            _additionalAPIParameters = newValue
        }
    }
}
