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
    /// Only the PaymentSheet, FlowController and Embedded load sends it (`sendsMobileSessionConfig`); other
    /// `elements/sessions` callers, like CustomerSheet, don't describe a real payment element configuration.
    static func configHeaders(for configuration: PaymentElementConfiguration) -> [String: String] {
        guard PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled else {
            return [:]
        }
        do {
            return [configHeaderName: try encodeHeaderValue(Config(configuration: configuration))]
        } catch {
            stpAssertionFailure("Failed to encode MobileSession.Config: \(error)")
            return [:]
        }
    }

    /// Returns the header value: compact JSON of the config with sorted keys, and every non-ASCII character
    /// written as a JSON `\uXXXX` escape so the header is always ASCII.
    static func encodeHeaderValue(_ config: Config) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(config)
        guard let json = String(bytes: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(
                config,
                EncodingError.Context(codingPath: [], debugDescription: "JSONEncoder produced invalid UTF-8")
            )
        }
        // Non-ASCII can only appear inside JSON strings, so escaping each UTF-16 code unit
        // (both halves of a surrogate pair for characters above U+FFFF) keeps the JSON valid.
        var ascii = ""
        ascii.reserveCapacity(json.utf16.count)
        for unit in json.utf16 {
            if unit < 0x80 {
                ascii.unicodeScalars.append(Unicode.Scalar(UInt8(unit)))
            } else {
                ascii += String(format: "\\u%04x", unit)
            }
        }
        return ascii
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
    init(configuration: PaymentElementConfiguration) {
        let hasDefaultEmail = !(configuration.defaultBillingDetails.email?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let billingDetailsCollection = configuration.billingDetailsCollectionConfiguration
        self.init(
            paymentElementConfig: .init(
                allowsDelayedPaymentMethods: configuration.allowsDelayedPaymentMethods,
                // Intentionally stricter than `fulfilledRequirements`, which treats "" as a return URL.
                hasReturnUrl: !(configuration.returnURL?.isEmpty ?? true),
                defaultBillingDetails: .init(email: hasDefaultEmail),
                billingDetailsCollection: .init(
                    name: .init(billingDetailsCollection.name),
                    phone: .init(billingDetailsCollection.phone),
                    email: .init(billingDetailsCollection.email),
                    address: .init(billingDetailsCollection.address),
                    attachDefaultsToPaymentMethod: billingDetailsCollection.attachDefaultsToPaymentMethod
                ),
                link: .init(displayMode: .init(configuration.link.display)),
                cardBrandAcceptance: .init(configuration.cardBrandAcceptance),
                paymentMethodOrder: configuration.paymentMethodOrder ?? []
            ),
            environment: .init(
                hasFinancialConnectionsSdk: FinancialConnectionsSDKAvailability.isFullFinancialConnectionsSDKAvailable,
                deviceSupportsNativeLink: Self.deviceSupportsNativeLink(apiClient: configuration.apiClient)
            )
        )
    }

    /// The device half of `deviceCanUseNativeLink`. The server combines it with the merchant's
    /// `link_mobile_use_attestation_endpoints` setting, which the client only learns from the response.
    static func deviceSupportsNativeLink(apiClient: STPAPIClient) -> Bool {
        if let nativeLinkEnabledOverride = PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride {
            return nativeLinkEnabledOverride
        }
        return apiClient.isTestmode || apiClient.stripeAttest.isSupported
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

extension MobileSession.AddressCollectionMode {
    init(_ addressCollectionMode: PaymentSheet.BillingDetailsCollectionConfiguration.AddressCollectionMode) {
        switch addressCollectionMode {
        case .automatic: self = .automatic
        case .never: self = .never
        case .full: self = .full
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

extension MobileSession.CardBrandAcceptance {
    init(_ cardBrandAcceptance: PaymentSheet.CardBrandAcceptance) {
        switch cardBrandAcceptance {
        case .all:
            self.init(filter: .all, brands: [])
        case .allowed(let brands):
            self.init(filter: .allowed, brands: brands.map(MobileSession.CardBrandCategory.init))
        case .disallowed(let brands):
            self.init(filter: .disallowed, brands: brands.map(MobileSession.CardBrandCategory.init))
        }
    }
}

extension MobileSession.CardBrandCategory {
    init(_ brandCategory: PaymentSheet.CardBrandAcceptance.BrandCategory) {
        switch brandCategory {
        case .visa: self = .visa
        case .mastercard: self = .mastercard
        case .amex: self = .amex
        case .discover: self = .discover
        }
    }
}
