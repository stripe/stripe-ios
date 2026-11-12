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

        /// Sends the `X-Stripe-Mobile-Config` header on `elements/sessions` and uses the server's
        /// `mobile_session.payment_method_availability` when it's present. Defaults to off.
        @_spi(InternalOnlyAPI) public static var serverPaymentMethodAvailabilityEnabled: Bool = false

        /// Confirms PaymentSheet's payments with `PaymentConfirmer`, for the types the session carries a `confirm` for.
        /// Off, STPPaymentHandler confirms every payment, including server-driven payment methods. Defaults to off.
        @_spi(InternalOnlyAPI) public static var paymentConfirmerEnabled: Bool = false

        #if DEBUG
        /// The playground's stand-in for the server: a `mobile_session` JSON object whose `payment_method_confirmations`
        /// every session uses in place of the ones the server serves. Only in DEBUG builds.
        @_spi(InternalOnlyAPI) public static var paymentMethodConfirmationsOverride: Data?
        #endif
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

    /// The decoded `mobile_session` sidecar.
    struct DecodedSidecar {
        let session: Session
        /// The types of the `payment_methods` entries that didn't decode and were dropped. A type left without a
        /// description shows natively if PaymentSheet supports it, and otherwise isn't shown.
        let undecodablePaymentMethodTypes: Set<String>
    }

    /// Decodes the `mobile_session` sidecar from an `elements/sessions` response.
    /// Returns nil when it's missing or malformed; never fails the load. A `payment_methods` or
    /// `payment_method_confirmations` entry that doesn't decode is dropped and reported, and the rest of the session is kept.
    static func decodeSidecar(fromAPIResponse response: [AnyHashable: Any]) -> DecodedSidecar? {
        guard let sidecar = response[sidecarResponseKey], !(sidecar is NSNull) else {
            return nil
        }
        do {
            guard JSONSerialization.isValidJSONObject(sidecar) else {
                throw PaymentSheetError.unknown(debugDescription: "mobile_session is not a JSON object")
            }
            var undecodablePaymentMethodTypes: Set<String> = []
            let session = try decode(JSONSerialization.data(withJSONObject: sidecar)) { droppedEntry in
                // The entry didn't decode, so read its type from the raw JSON, if it has one.
                let rawEntries = (sidecar as? [String: Any])?[droppedEntry.key] as? [Any]
                let type = rawEntries.flatMap { droppedEntry.index < $0.count ? $0[droppedEntry.index] : nil }
                    .flatMap { ($0 as? [String: Any])?["type"] as? String }
                // A dropped `payment_method_confirmations` entry only means the type is confirmed with STPPaymentHandler.
                if let type, droppedEntry.key == "payment_methods" {
                    undecodablePaymentMethodTypes.insert(type)
                }
                STPAnalyticsClient.sharedClient.logPaymentSheetEvent(
                    event: .paymentSheetMobileSessionPaymentMethodDropped,
                    error: droppedEntry.error,
                    params: [
                        "payment_method_type": type ?? "unknown",
                        "key": droppedEntry.key,
                        "reason": "decode",
                        "index": droppedEntry.index,
                    ]
                )
            }
            return DecodedSidecar(session: session, undecodablePaymentMethodTypes: undecodablePaymentMethodTypes)
        } catch {
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetMobileSessionDecodeFailed, error: error)
            return nil
        }
    }
}

extension STPElementsSession {
    /// The server's payment method availability, when the feature flag is on and the server sent it.
    var serverPaymentMethodAvailability: MobileSession.PaymentMethodAvailability? {
        guard PaymentSheet.MobileSessionFeatureFlags.serverPaymentMethodAvailabilityEnabled else {
            return nil
        }
        return mobileSession?.paymentMethodAvailability
    }

    /// The `payment_method_confirmations` entries to use for `mobileSession`: the served ones, or in DEBUG builds
    /// `paymentMethodConfirmationsOverride`'s when it's set.
    static func confirmationEntries(servedBy mobileSession: MobileSession.Session?) -> [MobileSession.PaymentMethodConfirmation] {
        #if DEBUG
        if let override = PaymentSheet.MobileSessionFeatureFlags.paymentMethodConfirmationsOverride {
            do {
                return try MobileSession.decode(override).paymentMethodConfirmations ?? []
            } catch {
                assertionFailure("paymentMethodConfirmationsOverride doesn't decode: \(error)")
            }
        }
        #endif
        return mobileSession?.paymentMethodConfirmations ?? []
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
                paymentMethodOrder: Self.trimmedPaymentMethodOrder(configuration.paymentMethodOrder ?? [])
            ),
            environment: .init(
                hasFinancialConnectionsSdk: FinancialConnectionsSDKAvailability.isFullFinancialConnectionsSDKAvailable,
                deviceSupportsNativeLink: Self.deviceSupportsNativeLink(apiClient: configuration.apiClient),
                displayLanguage: STPLocalizationUtils.displayLanguageTag(bundleLocator: StripePaymentSheetBundleLocator.self)
            )
        )
    }

    /// The most `payment_method_order` entries the header sends, and the longest entry.
    /// Together they keep the header under 2KB, a quarter of the server's 8KB limit per header.
    static let maxPaymentMethodOrderCount = 30
    static let maxPaymentMethodOrderEntryLength = 40

    /// Returns `paymentMethodOrder` without entries that can't name a payment method type, duplicates and entries past
    /// `maxPaymentMethodOrderCount`, since it's the only part of the header the merchant controls.
    /// It doesn't drop types the SDK doesn't know, since the server can describe payment methods the SDK can't name yet.
    static func trimmedPaymentMethodOrder(_ paymentMethodOrder: [String]) -> [String] {
        var seen = Set<String>()
        let trimmed = paymentMethodOrder.filter { type in
            let isPaymentMethodType = (1...maxPaymentMethodOrderEntryLength).contains(type.count)
                && type.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
            // The local ordering matches case-insensitively, so do the same for duplicates.
            return isPaymentMethodType && seen.insert(type.lowercased()).inserted
        }
        return Array(trimmed.prefix(maxPaymentMethodOrderCount))
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
