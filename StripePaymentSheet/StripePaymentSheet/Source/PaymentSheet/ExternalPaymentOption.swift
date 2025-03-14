//
//  ExternalPaymentOption.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 3/12/25.
//

import Foundation

enum ExternalPaymentOptionConfirmHandler {
    case custom(PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodType, PaymentSheet.CustomPaymentMethodConfiguration.CustomPaymentMethodConfirmHandler)
    case external(PaymentSheet.ExternalPaymentMethodConfiguration.ExternalPaymentMethodConfirmHandler)
}

/// A type that can represent either a custom or external payment method and handle confirmation
class ExternalPaymentOption {
    /// A unique identifier for the ExternalPaymentOption, like external_paypal or cpmt_...
    let type: String

    /// The display text for this external payment option, typically the name like "PayPal"
    let displayText: String

    /// Optional subtext to be shown below the display text
    let displaySubtext: String?

    /// URL of a 48x pixel tall, variable width PNG representing the payment method suitable for display against a light background color.
    let lightImageUrl: URL

    /// URL of a 48x pixel, variable width tall PNG representing the payment method suitable for display against a dark background color. If `nil`, use `lightImageUrl` instead.
    let darkImageUrl: URL?

    /// A function to be called when confirming a ExternalPaymentOption
    private let confirmHandler: ExternalPaymentOptionConfirmHandler

    private init(type: String, displayText: String, displaySubtext: String?, lightImageUrl: URL, darkImageUrl: URL?, confirmHandler: ExternalPaymentOptionConfirmHandler) {
        self.type = type
        self.displayText = displayText
        self.displaySubtext = displaySubtext
        self.lightImageUrl = lightImageUrl
        self.darkImageUrl = darkImageUrl
        self.confirmHandler = confirmHandler
    }

    /// Confirms the payment using this payment option.
    /// - Parameters:
    ///   - billingDetails: The billing details to use for confirmation
    ///   - completion: A closure that will be called with the payment result
    func confirm(billingDetails: STPPaymentMethodBillingDetails, completion: @escaping (PaymentSheetResult) -> Void) {
        switch confirmHandler {
        case .custom(let cpm, let confirmHandler):
            Task {
                let result = await confirmHandler(cpm, billingDetails)
                completion(result)
            }
        case .external(let confirmHandler):
            confirmHandler(type, billingDetails) { result in
                completion(result)
            }
        }
    }

    /// Creates an ExternalPaymentOption from an ExternalPaymentMethod.
    /// - Parameters:
    ///   - externalPaymentMethod: The external payment method to use
    ///   - configuration: `PaymentSheet.ExternalPaymentMethodConfiguration` containing the confirm handler
    /// - Returns: A new ExternalPaymentOption instance or nil if creation fails
    static func from(_ externalPaymentMethod: ExternalPaymentMethod, configuration: PaymentSheet.ExternalPaymentMethodConfiguration?) -> ExternalPaymentOption? {
        guard let confirmHandler = configuration?.externalPaymentMethodConfirmHandler else {
            assertionFailure("Attempting to create an external payment method, but externalPaymentMethodConfirmHandler isn't set!")
            return nil
        }

        return ExternalPaymentOption(
            type: externalPaymentMethod.type,
            displayText: externalPaymentMethod.label,
            displaySubtext: nil, // EPMs do not show any subtext
            lightImageUrl: externalPaymentMethod.lightImageUrl,
            darkImageUrl: externalPaymentMethod.darkImageUrl,
            confirmHandler: .external(confirmHandler)
        )
    }

    /// Creates an ExternalPaymentOption from a CustomPaymentMethod.
    /// - Parameters:
    ///   - customPaymentMethod: The custom payment method to use
    ///   - configuration: `PaymentSheet.CustomPaymentMethodConfiguration` containing the confirm handler and type information
    /// - Returns: A new ExternalPaymentOption instance or nil if creation fails
    static func from(_ customPaymentMethod: CustomPaymentMethod, configuration: PaymentSheet.CustomPaymentMethodConfiguration?) -> ExternalPaymentOption? {
        guard let confirmHandler = configuration?.customPaymentMethodConfirmHandler else {
            assertionFailure("Attempting to create an custom payment method, but customPaymentMethodConfirmHandler isn't set!")
            return nil
        }

        guard let customPaymentMethodType = configuration?.customPaymentMethodTypes.first(where: { $0.id == customPaymentMethod.type }),
              let label = customPaymentMethod.displayName,
              let logoUrl = customPaymentMethod.logoUrl else {
            assertionFailure("Failed to render payment method type: \(customPaymentMethod.type) with error \(customPaymentMethod.error ?? "unknown")")
            return nil
        }

        return ExternalPaymentOption(
            type: customPaymentMethod.type,
            displayText: label,
            displaySubtext: customPaymentMethodType.subcopy,
            lightImageUrl: logoUrl,
            darkImageUrl: nil, // CPMs don't have dark mode images
            confirmHandler: .custom(customPaymentMethodType, confirmHandler)
        )
    }
}

/// Note: ExternalPaymentOption equality is based solely on the type property, as it is a unique identifier.
extension ExternalPaymentOption: Equatable {
    static func == (lhs: ExternalPaymentOption, rhs: ExternalPaymentOption) -> Bool {
        return lhs.type == rhs.type
    }
}

extension ExternalPaymentOption: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
}
