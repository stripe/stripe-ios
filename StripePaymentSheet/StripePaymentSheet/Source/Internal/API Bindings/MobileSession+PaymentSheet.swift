//
//  MobileSession+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/4/26.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

extension PaymentSheet {

    @_spi(InternalOnlyAPI) public enum MobileSessionFeatureFlags {

        /// Sends the `X-Stripe-Mobile-Config` header on `elements/sessions` and decodes the
        /// `mobile_session` sidecar from the response. Defaults to off.
        @_spi(InternalOnlyAPI) public static var serverPaymentMethodAvailabilityEnabled: Bool = false
    }
}

extension MobileSession {
    static let sidecarResponseKey = "mobile_session"

    /// Returns the `X-Stripe-Mobile-Config` header for `configuration`, or no headers when the feature flag is off.
    static func configHeaders(for configuration: PaymentElementConfiguration) -> [String: String] {
        guard PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled else {
            return [:]
        }
        do {
            return [configHeaderName: try encode(Config(configuration: configuration))]
        } catch {
            stpAssertionFailure("Failed to encode MobileSession.Config: \(error)")
            return [:]
        }
    }

    /// Decodes the `mobile_session` sidecar from an `elements/sessions` response.
    /// Returns nil when it's missing or malformed; never fails the load.
    static func decodeSidecar(fromAPIResponse response: [AnyHashable: Any]) -> Session? {
        guard let sidecar = response[sidecarResponseKey], !(sidecar is NSNull) else {
            return nil
        }
        do {
            guard JSONSerialization.isValidJSONObject(sidecar) else {
                throw PaymentSheetError.unknown(debugDescription: "mobile_session is not a JSON object")
            }
            return try decode(JSONSerialization.data(withJSONObject: sidecar))
        } catch {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetMobileSessionDecodeFailed, error: error)
            return nil
        }
    }
}

extension MobileSession.Config {
    /// Maps each field explicitly. Only booleans and policies go over the wire, never customer values.
    init(
        configuration: PaymentElementConfiguration,
        hasFinancialConnectionsSdk: Bool = FinancialConnectionsSDKAvailability.isFullFinancialConnectionsSDKAvailable
    ) {
        let hasDefaultEmail = !(configuration.defaultBillingDetails.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        self.init(
            paymentElementConfig: .init(
                allowsDelayedPaymentMethods: configuration.allowsDelayedPaymentMethods,
                // Intentionally stricter than `fulfilledRequirements`, which treats "" as a return URL.
                hasReturnUrl: !(configuration.returnURL?.isEmpty ?? true),
                defaultBillingDetails: .init(email: hasDefaultEmail),
                billingDetailsCollection: .init(
                    email: .init(configuration.billingDetailsCollectionConfiguration.email),
                    attachDefaultsToPaymentMethod: configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod
                ),
                link: .init(displayMode: .init(configuration.link.display)),
                paymentMethodOrder: configuration.paymentMethodOrder
            ),
            environment: .init(hasFinancialConnectionsSdk: hasFinancialConnectionsSdk)
        )
    }
}

extension MobileSession.CollectionMode {
    init(_ collectionMode: PaymentSheet.BillingDetailsCollectionConfiguration.CollectionMode) {
        switch collectionMode {
        case .automatic: self = .automatic
        case .never: self = .never
        case .always: self = .always
        }
    }
}

extension MobileSession.LinkDisplay {
    init(_ display: PaymentSheet.LinkConfiguration.Display) {
        switch display {
        case .automatic: self = .automatic
        case .never: self = .never
        case .walletButtonHidden: self = .walletButtonHidden
        }
    }
}
