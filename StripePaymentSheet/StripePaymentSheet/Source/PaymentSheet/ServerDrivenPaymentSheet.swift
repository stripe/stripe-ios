//
//  ServerDrivenPaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Stripe on 6/3/26.
//

import Foundation
import ObjectiveC
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Toy client-side model for a future server-driven PaymentSheet endpoint.
struct ServerDrivenPaymentSheetResponse {
    let mobileTeamContact: String
    let sdkVersionHeader: String
    let serializedConfiguration: SerializedConfiguration
    let features: Features
    let paymentMethodTypes: [String]
    let assets: Assets
    let formSpecs: [[String: Any]]

    struct SerializedConfiguration: Equatable {
        let merchantDisplayName: String
        let allowsDelayedPaymentMethods: Bool
        let allowsPaymentMethodsRequiringShippingAddress: Bool
        let hasApplePay: Bool
        let linkEnabled: Bool
        let returnURLProvided: Bool
        let paymentMethodOrder: [String]?
        let billingDetailsCollection: [String: String]
        let defaultBillingDetails: [String: String]
        let mode: String
        let amount: Int?
        let currency: String?
    }

    struct Features: Equatable {
        enum FinancialConnectionsLite: Equatable {
            case automatic
            case disabled
            case preferred

            var fcLiteKillswitchEnabled: Bool {
                self == .disabled
            }

            var remoteFcLiteOverrideEnabled: Bool {
                self == .preferred
            }
        }

        static let defaults = Features(
            financialConnectionsLite: .automatic,
            linkGlobalHoldbackLookup: true,
            forceVerticalPaymentMethodLayout: false,
            cardFundingFiltering: false
        )

        let financialConnectionsLite: FinancialConnectionsLite
        let linkGlobalHoldbackLookup: Bool
        let forceVerticalPaymentMethodLayout: Bool
        let cardFundingFiltering: Bool
    }

    struct Assets {
        let paymentMethodDisplayNames: [String: String]
        let selectorIconURLs: [String: SelectorIcon]

        struct SelectorIcon {
            let lightThemePNG: String
            let darkThemePNG: String?
        }
    }
}

final class ServerDrivenPaymentSheetAssetStore {
    static let shared = ServerDrivenPaymentSheetAssetStore()

    private var paymentMethodDisplayNames: [String: String] = [:]
    private let lock = NSLock()

    func install(_ assets: ServerDrivenPaymentSheetResponse.Assets) {
        lock.lock()
        paymentMethodDisplayNames = assets.paymentMethodDisplayNames
        lock.unlock()
    }

    func displayName(for paymentMethodType: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return paymentMethodDisplayNames[paymentMethodType]
    }
}

enum ServerDrivenPaymentSheetMockServer {
    static var isEnabled = true
    private typealias NativeExternalPaymentMethodMetadata = (subtitle: String?, disableBillingDetailCollection: Bool?)

    static func load(
        configuration: PaymentElementConfiguration,
        intent: Intent,
        elementsSession: STPElementsSession
    ) -> ServerDrivenPaymentSheetResponse? {
        guard isEnabled else {
            return nil
        }

        let serializedConfiguration = ServerDrivenPaymentSheetResponse.SerializedConfiguration(
            merchantDisplayName: configuration.merchantDisplayName,
            allowsDelayedPaymentMethods: configuration.allowsDelayedPaymentMethods,
            allowsPaymentMethodsRequiringShippingAddress: configuration.allowsPaymentMethodsRequiringShippingAddress,
            hasApplePay: configuration.applePay != nil,
            linkEnabled: configuration.link.shouldDisplay,
            returnURLProvided: configuration.returnURL != nil,
            paymentMethodOrder: configuration.paymentMethodOrder,
            billingDetailsCollection: [
                "name": String(describing: configuration.billingDetailsCollectionConfiguration.name),
                "email": String(describing: configuration.billingDetailsCollectionConfiguration.email),
                "phone": String(describing: configuration.billingDetailsCollectionConfiguration.phone),
                "address": String(describing: configuration.billingDetailsCollectionConfiguration.address),
            ],
            defaultBillingDetails: [
                "name": configuration.defaultBillingDetails.name,
                "email": configuration.defaultBillingDetails.email,
                "phone": configuration.defaultBillingDetails.phone,
                "line1": configuration.defaultBillingDetails.address.line1,
                "postal_code": configuration.defaultBillingDetails.address.postalCode,
                "country": configuration.defaultBillingDetails.address.country,
            ].compactMapValues { $0 },
            mode: intent.isPaymentIntent ? "payment" : "setup",
            amount: intent.amount,
            currency: intent.currency
        )

        let serverApprovedPaymentMethods = paymentMethodTypes(
            configuration: configuration,
            elementsSession: elementsSession
        )
        let assets = makeAssets(for: serverApprovedPaymentMethods)

        return ServerDrivenPaymentSheetResponse(
            mobileTeamContact: "mobile-paymentsheet-backend@example.invalid",
            sdkVersionHeader: STPAPIClient.mobileSDKVersionHeaderValue,
            serializedConfiguration: serializedConfiguration,
            features: .init(
                financialConnectionsLite: .preferred,
                linkGlobalHoldbackLookup: true,
                forceVerticalPaymentMethodLayout: serverApprovedPaymentMethods.count > 1,
                cardFundingFiltering: configuration.allowedCardFundingTypes != .all
            ),
            paymentMethodTypes: serverApprovedPaymentMethods,
            assets: assets,
            formSpecs: makeFormSpecs(
                for: serverApprovedPaymentMethods,
                intent: intent,
                assets: assets,
                nativeExternalPaymentMethodMetadata: nativeExternalPaymentMethodMetadata(
                    configuration: configuration,
                    elementsSession: elementsSession
                )
            )
        )
    }

    private static func paymentMethodTypes(
        configuration: PaymentElementConfiguration,
        elementsSession: STPElementsSession
    ) -> [String] {
        var paymentMethodTypes = elementsSession.orderedPaymentMethodTypes
            .filter { $0 != .unknown }
            .map(\.identifier)

        if let externalPaymentMethodConfiguration = configuration.externalPaymentMethodConfiguration {
            let configuredExternalPaymentMethodTypes = Set(externalPaymentMethodConfiguration.externalPaymentMethods)
            paymentMethodTypes.append(
                contentsOf: elementsSession.externalPaymentMethods
                    .map(\.type)
                    .filter { configuredExternalPaymentMethodTypes.contains($0) }
            )
        }

        if let customPaymentMethodConfiguration = configuration.customPaymentMethodConfiguration {
            let configuredCustomPaymentMethodTypes = Set(customPaymentMethodConfiguration.customPaymentMethods.map(\.id))
            paymentMethodTypes.append(
                contentsOf: elementsSession.customPaymentMethods
                    .map(\.type)
                    .filter { configuredCustomPaymentMethodTypes.contains($0) }
            )
        }

        if let paymentMethodOrder = configuration.paymentMethodOrder {
            paymentMethodTypes.sort { lhs, rhs in
                let lhsIndex = paymentMethodOrder.firstIndex(of: lhs) ?? Int.max
                let rhsIndex = paymentMethodOrder.firstIndex(of: rhs) ?? Int.max
                return lhsIndex < rhsIndex
            }
        }
        return paymentMethodTypes
    }

    private static func makeAssets(for paymentMethodTypes: [String]) -> ServerDrivenPaymentSheetResponse.Assets {
        var displayNames = [
            "card": "Card",
            "sepa_debit": "SEPA Direct Debit",
        ]
        displayNames = displayNames.filter { paymentMethodTypes.contains($0.key) }

        let icons = paymentMethodTypes.reduce(into: [String: ServerDrivenPaymentSheetResponse.Assets.SelectorIcon]()) { result, paymentMethodType in
            result[paymentMethodType] = .init(
                lightThemePNG: "https://js.stripe.com/v3/fingerprinted/img/\(paymentMethodType)-light.png",
                darkThemePNG: "https://js.stripe.com/v3/fingerprinted/img/\(paymentMethodType)-dark.png"
            )
        }
        return .init(paymentMethodDisplayNames: displayNames, selectorIconURLs: icons)
    }

    private static func makeFormSpecs(
        for paymentMethodTypes: [String],
        intent: Intent,
        assets: ServerDrivenPaymentSheetResponse.Assets,
        nativeExternalPaymentMethodMetadata: [String: NativeExternalPaymentMethodMetadata]
    ) -> [[String: Any]] {
        paymentMethodTypes.compactMap { paymentMethodType in
            if let fields = formFields(for: paymentMethodType, intent: intent) {
                return formSpec(
                    type: paymentMethodType,
                    fields: fields,
                    icon: assets.selectorIconURLs[paymentMethodType]
                )
            }
            if let nativeFormType = nativeFormType(for: paymentMethodType) {
                let metadata = nativeExternalPaymentMethodMetadata[paymentMethodType]
                let subtitle = metadata?.subtitle
                let disableBillingDetailCollection = metadata?.disableBillingDetailCollection
                return nativeFormSpec(
                    type: paymentMethodType,
                    formType: nativeFormType,
                    icon: assets.selectorIconURLs[paymentMethodType],
                    subtitle: subtitle,
                    disableBillingDetailCollection: disableBillingDetailCollection
                )
            }
            if let nativeMandateType = nativeMandateType(for: paymentMethodType),
               intent.isSetupFutureUsageSet(for: STPPaymentMethod.type(from: paymentMethodType))
            {
                return formSpec(
                    type: paymentMethodType,
                    fields: [
                        [
                            "type": "native_mandate",
                            "mandate_type": nativeMandateType,
                        ],
                    ],
                    icon: assets.selectorIconURLs[paymentMethodType]
                )
            }
            return formSpec(type: paymentMethodType, fields: [], icon: assets.selectorIconURLs[paymentMethodType])
        }
    }

    private static func nativeExternalPaymentMethodMetadata(
        configuration: PaymentElementConfiguration,
        elementsSession: STPElementsSession
    ) -> [String: NativeExternalPaymentMethodMetadata] {
        var metadata: [String: NativeExternalPaymentMethodMetadata] = [:]

        if let externalPaymentMethodConfiguration = configuration.externalPaymentMethodConfiguration {
            let configuredExternalPaymentMethodTypes = Set(externalPaymentMethodConfiguration.externalPaymentMethods)
            for externalPaymentMethod in elementsSession.externalPaymentMethods where configuredExternalPaymentMethodTypes.contains(externalPaymentMethod.type) {
                metadata[externalPaymentMethod.type] = (subtitle: nil, disableBillingDetailCollection: false)
            }
        }

        if let customPaymentMethodConfiguration = configuration.customPaymentMethodConfiguration {
            for customPaymentMethod in customPaymentMethodConfiguration.customPaymentMethods {
                metadata[customPaymentMethod.id] = (
                    subtitle: customPaymentMethod.subtitle,
                    disableBillingDetailCollection: customPaymentMethod.disableBillingDetailCollection
                )
            }
        }

        return metadata
    }

    private static func nativeFormType(for paymentMethodType: String) -> String? {
        [
            "card": "card",
            "us_bank_account": "us_bank_account",
            "instant_debits": "instant_debits",
            "link_card_brand": "instant_debits",
            "external_payment_method": "external_payment_method",
            "bacs_debit": "bacs_debit",
            "blik": "blik",
            "konbini": "konbini",
            "boleto": "boleto",
        ][paymentMethodType] ?? {
            if paymentMethodType.hasPrefix("external_") || paymentMethodType.hasPrefix("cpmt_") {
                return "external_payment_method"
            }
            return nil
        }()
    }

    private static func formFields(for paymentMethodType: String, intent: Intent) -> [[String: Any]]? {
        let isSettingUp = intent.isSetupFutureUsageSet(for: STPPaymentMethod.type(from: paymentMethodType))
        let emailField = isSettingUp ? field("email") : placeholder("email")

        switch paymentMethodType {
        case "sepa_debit":
            return [
                field("name"),
                field("email"),
                placeholder("phone"),
                field("iban", apiPath: "sepa_debit[iban]"),
                [
                    "type": "billing_address",
                    "allowed_country_codes": NSNull(),
                ],
                field("sepa_mandate"),
            ]
        case "bancontact":
            return [
                field("name"),
                emailField,
                placeholder("phone"),
                placeholder("billing_address"),
                nativeMandateField(type: "sepa", setupFutureUsageRequired: true),
            ]
        case "klarna":
            return [
                field("klarna_header"),
                placeholder("name"),
                field("email"),
                placeholder("phone"),
                field("klarna_country"),
                placeholder("billing_address_without_country"),
                nativeMandateField(type: "klarna", setupFutureUsageRequired: true),
            ]
        case "afterpay_clearpay":
            return [
                field("afterpay_header"),
                field("name"),
                field("email"),
                placeholder("phone"),
                placeholder("billing_address"),
            ]
        case "affirm":
            return [
                field("affirm_header"),
                placeholder("name"),
                placeholder("email"),
                placeholder("phone"),
                placeholder("billing_address"),
            ]
        case "ideal":
            return [
                field("name"),
                emailField,
                placeholder("phone"),
                placeholder("billing_address"),
                nativeMandateField(type: "sepa", setupFutureUsageRequired: true),
            ]
        case "oxxo":
            return [
                field("name"),
                field("email"),
                placeholder("phone"),
                placeholder("billing_address"),
            ]
        case "swish":
            return [
                placeholder("name"),
                placeholder("email"),
                placeholder("phone"),
                placeholder("billing_address"),
            ]
        case "wero":
            return [
                [
                    "type": "country",
                    "allowed_country_codes": ["DE", "BE", "FR"],
                ],
                placeholder("name"),
                placeholder("email"),
                placeholder("phone"),
                placeholder("billing_address"),
            ]
        default:
            return nil
        }
    }

    private static func field(_ type: String, apiPath: String? = nil) -> [String: Any] {
        var field: [String: Any] = ["type": type]
        if let apiPath {
            field["api_path"] = ["v1": apiPath]
        }
        return field
    }

    private static func placeholder(_ field: String) -> [String: Any] {
        [
            "type": "placeholder",
            "for": field,
        ]
    }

    private static func nativeMandateField(type: String, setupFutureUsageRequired: Bool) -> [String: Any] {
        [
            "type": "native_mandate",
            "mandate_type": type,
            "setup_future_usage_required": setupFutureUsageRequired,
        ]
    }

    private static func nativeMandateType(for paymentMethodType: String) -> String? {
        [
            "cashapp": "cashapp",
            "paypal": "paypal",
            "revolut_pay": "revolut_pay",
            "amazon_pay": "amazon_pay",
            "satispay": "satispay",
            "twint": "twint",
        ][paymentMethodType]
    }

    private static func nativeFormSpec(
        type: String,
        formType: String,
        icon: ServerDrivenPaymentSheetResponse.Assets.SelectorIcon?,
        subtitle: String? = nil,
        disableBillingDetailCollection: Bool? = nil
    ) -> [String: Any] {
        var nativeFormField: [String: Any] = [
            "type": "native_payment_method_form",
            "form_type": formType,
        ]
        nativeFormField["subtitle"] = subtitle
        nativeFormField["disable_billing_detail_collection"] = disableBillingDetailCollection

        return formSpec(
            type: type,
            fields: [nativeFormField],
            icon: icon
        )
    }

    private static func formSpec(
        type: String,
        fields: [[String: Any]],
        icon: ServerDrivenPaymentSheetResponse.Assets.SelectorIcon?
    ) -> [String: Any] {
        var spec: [String: Any] = [
            "type": type,
            "fields": fields,
        ]
        if let icon {
            var selectorIcon: [String: Any] = [
                "light_theme_png": icon.lightThemePNG,
            ]
            selectorIcon["dark_theme_png"] = icon.darkThemePNG
            spec["selector_icon"] = selectorIcon
        }
        return spec
    }
}

private var serverDrivenPaymentSheetAssociationKey: UInt8 = 0

extension STPElementsSession {
    var serverDrivenPaymentSheet: ServerDrivenPaymentSheetResponse? {
        get {
            objc_getAssociatedObject(self, &serverDrivenPaymentSheetAssociationKey) as? ServerDrivenPaymentSheetResponse
        }
        set {
            objc_setAssociatedObject(
                self,
                &serverDrivenPaymentSheetAssociationKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    var serverDrivenFeatures: ServerDrivenPaymentSheetResponse.Features {
        serverDrivenPaymentSheet?.features ?? .defaults
    }
}
