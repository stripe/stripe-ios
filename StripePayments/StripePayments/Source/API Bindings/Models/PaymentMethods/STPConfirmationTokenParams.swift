//
//  STPConfirmationTokenParams.swift
//  StripePayments
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// An object representing parameters used to create a ConfirmationToken object.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
public class STPConfirmationTokenParams: NSObject, STPFormEncodable {
    private var _additionalAPIParameters: [AnyHashable: Any] = [:]

    /// ID of an existing PaymentMethod to use for this ConfirmationToken.
    @objc public var paymentMethod: String?

    /// Payment method details for the ConfirmationToken.
    @objc public var paymentMethodData: STPConfirmationTokenPaymentMethodData?

    /// Payment-method-specific configuration for this ConfirmationToken.
    @objc public var paymentMethodOptions: STPConfirmationTokenPaymentMethodOptions?

    /// Return URL to redirect the customer back to your application after completion of 3D Secure authentication.
    @objc public var returnURL: String?

    /// Indicates that you intend to make future payments with the payment method collected during checkout.
    @objc public var setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none

    /// Shipping information to include with the ConfirmationToken.
    @objc public var shipping: STPPaymentIntentShippingDetailsParams?

    /// Convenience initializer for creating a ConfirmationToken with payment method data.
    /// - Parameters:
    ///   - paymentMethodData: Payment method details for the ConfirmationToken. Cannot be nil.
    ///   - returnURL: Return URL for redirect-based payment methods. Can be nil.
    @objc public convenience init(
        paymentMethodData: STPConfirmationTokenPaymentMethodData,
        returnURL: String? = nil
    ) {
        self.init()
        self.paymentMethodData = paymentMethodData
        self.returnURL = returnURL
    }

    /// Convenience initializer for creating a ConfirmationToken from existing PaymentMethodParams.
    /// - Parameters:
    ///   - paymentMethodParams: Existing payment method parameters to convert
    ///   - returnURL: Return URL for redirect-based payment methods. Can be nil.
    @objc public convenience init(
        paymentMethodParams: STPPaymentMethodParams,
        returnURL: String? = nil
    ) {
        self.init()
        self.paymentMethodData = STPConfirmationTokenPaymentMethodData(from: paymentMethodParams)
        self.returnURL = returnURL
    }

    /// Convenience initializer for creating a ConfirmationToken with card payment method data.
    /// - Parameters:
    ///   - card: An object containing the user's card details.
    ///   - billingDetails: An object containing the user's billing details.
    ///   - allowRedisplay: An enum defining consent options for redisplay
    ///   - metadata: Additional information to attach to the PaymentMethod.
    ///   - returnURL: Return URL for redirect-based payment methods. Can be nil.
    @objc public convenience init(
        card: STPPaymentMethodCardParams,
        billingDetails: STPPaymentMethodBillingDetails?,
        allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified,
        metadata: [String: String]? = nil,
        returnURL: String? = nil
    ) {
        self.init()
        self.paymentMethodData = STPConfirmationTokenPaymentMethodData(
            card: card,
            billingDetails: billingDetails,
            allowRedisplay: allowRedisplay,
            metadata: metadata
        )
        self.returnURL = returnURL
    }

    /// Convenience initializer for creating a ConfirmationToken with SEPA Debit payment method data.
    /// - Parameters:
    ///   - sepaDebit: An object containing the SEPA bank debit details.
    ///   - billingDetails: An object containing the user's billing details. Note that `billingDetails.name` is required for SEPA Debit PaymentMethods.
    ///   - allowRedisplay: An enum defining consent options for redisplay
    ///   - metadata: Additional information to attach to the PaymentMethod.
    ///   - returnURL: Return URL for redirect-based payment methods. Can be nil.
    @objc public convenience init(
        sepaDebit: STPPaymentMethodSEPADebitParams,
        billingDetails: STPPaymentMethodBillingDetails,
        allowRedisplay: STPPaymentMethodAllowRedisplay = .unspecified,
        metadata: [String: String]? = nil,
        returnURL: String? = nil
    ) {
        self.init()
        self.paymentMethodData = STPConfirmationTokenPaymentMethodData(
            sepaDebit: sepaDebit,
            billingDetails: billingDetails,
            allowRedisplay: allowRedisplay,
            metadata: metadata
        )
        self.returnURL = returnURL
    }

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

// MARK: - Validation

extension STPConfirmationTokenParams {
    /// Validates the ConfirmationToken parameters.
    /// - Returns: An error if the parameters are invalid, nil otherwise.
    @objc public func validate() -> Error? {
        guard let paymentMethodData = paymentMethodData else {
            return NSError.stp_confirmationTokenMissingPaymentMethodDataError()
        }

        // Validate payment method type is supported
        switch paymentMethodData.type {
        case .unknown:
            return NSError.stp_confirmationTokenUnsupportedPaymentMethodTypeError()
        default:
            break
        }

        // Validate return URL format if provided
        if let returnURL = returnURL {
            guard URL(string: returnURL) != nil else {
                return NSError.stp_confirmationTokenInvalidReturnURLError()
            }
        }

        return nil
    }
}
