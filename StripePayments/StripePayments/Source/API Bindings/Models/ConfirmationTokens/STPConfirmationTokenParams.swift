//
//  STPConfirmationTokenParams.swift
//  StripePayments
//
//  Created by Nick Porter on 9/2/25.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

/// An object representing parameters used to create a ConfirmationToken object.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
@_spi(InternalOnlyAPI) public class STPConfirmationTokenParams: NSObject, STPFormEncodable {
    private var _additionalAPIParameters: [AnyHashable: Any] = [:]

    /// ID of an existing PaymentMethod to use for this ConfirmationToken.
    public var paymentMethod: String?

    /// Payment method details for the ConfirmationToken.
    public var paymentMethodData: STPPaymentMethodParams?

    /// Payment-method-specific configuration for this ConfirmationToken.
    public var paymentMethodOptions: STPConfirmPaymentMethodOptions?

    /// Return URL to redirect the customer back to your application after completion of 3D Secure authentication.
    public var returnURL: String?

    /// Indicates that you intend to make future payments with the payment method collected during checkout.
    public var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none

    /// Shipping information to include with the ConfirmationToken.
    public var shipping: STPPaymentIntentShippingDetailsParams?

    /// Details about the Mandate to create.
    public var mandateData: STPMandateDataParams?

    /// `@YES` to set this ConfirmationToken's PaymentMethod as the associated Customer's default
    /// This should be a boolean NSNumber, so that it can be `nil`
    @_spi(InternalOnlyAPI) public var setAsDefaultPM: NSNumber?

    /// Contains metadata with identifiers for the session and information about the integration
    @_spi(InternalOnlyAPI) public var clientAttributionMetadata: STPClientAttributionMetadata?

    /// Client context for the ConfirmationToken, containing information about the payment flow context
    @_spi(InternalOnlyAPI) public var clientContext: STPConfirmationTokenClientContext?

    /// :nodoc:
    public override var description: String {
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

    public static func rootObjectName() -> String? {
        return nil
    }

    public static func propertyNamesToFormFieldNamesMapping() -> [AnyKeyPath: String] {
        return [
            \STPConfirmationTokenParams.paymentMethod: "payment_method",
            \STPConfirmationTokenParams.paymentMethodData: "payment_method_data",
            \STPConfirmationTokenParams.paymentMethodOptions: "payment_method_options",
            \STPConfirmationTokenParams.returnURL: "return_url",
            \STPConfirmationTokenParams.shipping: "shipping",
            \STPConfirmationTokenParams.mandateData: "mandate_data",
            \STPConfirmationTokenParams.setAsDefaultPM: "set_as_default_payment_method",
            \STPConfirmationTokenParams.clientAttributionMetadata: "client_attribution_metadata",
            \STPConfirmationTokenParams.clientContext: "client_context",
        ]
    }

    public var additionalAPIParameters: [AnyHashable: Any] {
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
