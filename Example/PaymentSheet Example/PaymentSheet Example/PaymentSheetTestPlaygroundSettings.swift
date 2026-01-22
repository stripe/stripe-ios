//
//  PaymentSheetTestPlaygroundSettings.swift
//  PaymentSheet Example
//
//  Created by David Estes on 5/31/23.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(PaymentMethodOptionsSetupFutureUsagePreview) @_spi(CardFundingFilteringPrivatePreview) import StripePaymentSheet

struct PaymentSheetTestPlaygroundSettings: Codable, Equatable {
    enum UIStyle: String, PickerEnum {
        static var enumName: String { "UI" }

        case paymentSheet
        case flowController
        case embedded
    }

    enum Mode: String, PickerEnum {
        static var enumName: String { "Mode" }

        case payment
        case paymentWithSetup = "payment_with_setup"
        case setup

        var displayName: String {
            switch self {
            case .payment:
                return "Payment"
            case .paymentWithSetup:
                return "Pay+SFU"
            case .setup:
                return "Setup"
            }
        }
    }

    enum Layout: String, PickerEnum {
        static var enumName: String { "Layout" }
        case horizontal
        case vertical
        case automatic
    }

    enum IntegrationType: String, PickerEnum {
        static var enumName: String { "Type" }

        // Normal: Normal client side confirmation non-deferred flow
        case normal
        /// Def CSC: Deferred client side confirmation
        case deferred_csc
        /// Def SSC: Deferred server side confirmation
        case deferred_ssc
        /// Def MC: Deferred server side confirmation with manual confirmation
        case deferred_mc
        /// Def MP: Deferred multiprocessor flow
        case deferred_mp
        /// CheckoutSession: Uses Stripe CheckoutSession APIs
        case checkoutSession

        var displayName: String {
            switch self {
            case .normal:
                return "Client-side confirmation"
            case .deferred_csc:
                return "Deferred client side confirmation"
            case .deferred_ssc:
                return "Deferred server side confirmation"
            case .deferred_mc:
                return "Deferred server side confirmation with manual confirmation"
            case .deferred_mp:
                return "Deferred multiprocessor flow"
            case .checkoutSession:
                return "Checkout Session"
            }
        }

        var isIntentFirst: Bool {
            switch self {
            case .normal, .checkoutSession:
                return true
            case .deferred_csc, .deferred_ssc, .deferred_mc, .deferred_mp:
                return false
            }
        }
    }

    enum ConfirmationMode: String, PickerEnum {
        static var enumName: String { "Confirmation mode" }

        case confirmationToken = "ConfirmationToken"
        case paymentMethod = "PaymentMethod"
    }

    enum CustomerMode: String, PickerEnum {
        static var enumName: String { "Customer" }

        case guest
        case new
        case returning
    }
    enum CustomerKeyType: String, PickerEnum {
        static var enumName: String { "CustomerKeyType" }

        case legacy
        case customerSession = "customer_session"
    }

    enum Amount: Int, PickerEnum {
        static var enumName: String { "Amount" }

        case _5099 = 5099
        case _10000 = 10000

        var displayName: String {
            switch self {
            case ._5099:
                return "50.99"
            case ._10000:
                return "100.00"
            }
        }
        func customDisplayName(currency: Currency) -> String {
            switch currency {
            case .jpy:
                return displayName.replacingOccurrences(of: ".", with: "")
            default:
                return displayName
            }
        }
    }

    enum Currency: String, PickerEnum {
        static var enumName: String { "Currency" }

        case usd
        case eur
        case aud
        case gbp
        case inr
        case pln
        case sgd
        case myr
        case mxn
        case jpy
        case brl
        case thb
        case sek
        case chf
    }

    enum MerchantCountry: String, PickerEnum {
        static var enumName: String { "Merchant" }

        case US
        case GB
        case AU
        case FR
        case IN
        case SG
        case MY
        case MX
        case JP
        case BR
        case TH
        case DE
        case IT
        case stripeShop = "stripe_shop_test"
        case custom
    }

    enum APMSEnabled: String, PickerEnum {
        static var enumName: String { "Automatic PMs" }

        case on
        case off
    }

    struct PaymentMethodOptionsSetupFutureUsage: Codable, Equatable {
        // Supports all SFU values
        var card: SetupFutureUsageAll
        var usBankAccount: SetupFutureUsageAll
        var sepaDebit: SetupFutureUsageAll
        // Only supports off_session
        var link: SetupFutureUsageOffSessionOnly
        var klarna: SetupFutureUsageOffSessionOnly
        // Does not support SFU
        var affirm: SetupFutureUsageNone

        var additionalPaymentMethodOptionsSetupFutureUsage: String?

        static func defaultValues() -> PaymentMethodOptionsSetupFutureUsage {
            return PaymentMethodOptionsSetupFutureUsage(
                card: .unset,
                usBankAccount: .unset,
                sepaDebit: .unset,
                link: .unset,
                klarna: .unset,
                affirm: .unset
            )
        }

        func toDictionary() -> [String: String] {
            var result: [String: String] = [:]
            if card != .unset {
                result["card"] = card.rawValue
            }
            if usBankAccount != .unset {
                result["us_bank_account"] = usBankAccount.rawValue
            }
            if sepaDebit != .unset {
                result["sepa_debit"] = sepaDebit.rawValue
            }
            if link != .unset {
                result["link"] = link.rawValue
            }
            if klarna != .unset {
                result["klarna"] = klarna.rawValue
            }
            if affirm != .unset {
                result["affirm"] = affirm.rawValue
            }
            if let additionalPaymentMethodOptionsSetupFutureUsage {
                // get the "key:value" strings by splitting on the comma
                let paymentMethodOptionsSetupFutureUsage = additionalPaymentMethodOptionsSetupFutureUsage
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: ",")
                    .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                paymentMethodOptionsSetupFutureUsage.forEach {
                    // get the "key" and the "value"
                    let components = $0
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .split(separator: ":")
                        .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                    if let paymentMethodType = components.first, !paymentMethodType.isEmpty,
                       let setupFutureUsageValue = components.last, !setupFutureUsageValue.isEmpty,
                       // picker value takes precedence over text input value if picker value is not unset
                       result[paymentMethodType] == nil {
                        result[paymentMethodType] = setupFutureUsageValue
                    }
                }
            }
            return result
        }

        func makePaymentMethodOptions() -> PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions {
            let paymentMethodOptionsSetupFutureUsageDictionary: [String: String] = toDictionary()
            let setupFutureUsageValues: [STPPaymentMethodType: PaymentSheet.IntentConfiguration.SetupFutureUsage] = {
                var result: [STPPaymentMethodType: PaymentSheet.IntentConfiguration.SetupFutureUsage] = [:]
                paymentMethodOptionsSetupFutureUsageDictionary.forEach { paymentMethodTypeIdentifier, setupFutureUsageString in
                    let paymentMethodType = STPPaymentMethodType.fromIdentifier(paymentMethodTypeIdentifier)
                    let setupFutureUsage = PaymentSheet.IntentConfiguration.SetupFutureUsage(rawValue: setupFutureUsageString)
                    result[paymentMethodType] = setupFutureUsage
                }
                return result
            }()
            return PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: setupFutureUsageValues)
        }

    }

    enum SetupFutureUsageAll: String, PickerEnum {
        static var enumName: String { "SetupFutureUsage" }
        case unset
        case off_session
        case on_session
        case none
    }

    enum SetupFutureUsageOffSessionOnly: String, PickerEnum {
        static var enumName: String { "SetupFutureUsage" }
        case unset
        case off_session
        case none
    }

    enum SetupFutureUsageNone: String, PickerEnum {
        static var enumName: String { "SetupFutureUsage" }
        case unset
        case none
    }

    enum ShippingInfo: String, PickerEnum {
        static var enumName: String { "Shipping info" }

        case on
        case onWithDefaults = "on w/ defaults"
        case off
    }

    enum ApplePayEnabled: String, PickerEnum {
        static var enumName: String { "Apple Pay" }

        case on
        case off
        case onWithDetails = "on w/details"
        case onWithShipping = "on w/Shipping"
    }

    enum ApplePayButtonType: String, PickerEnum {
        static var enumName: String { "Pay button" }

        case plain
        case buy
        case setup
        case checkout
    }

    enum LinkDisplay: String, PickerEnum {
        static var enumName: String { "Link display" }

        case automatic
        case never
    }

    enum AllowsDelayedPMs: String, PickerEnum {
        static var enumName: String { "allowsDelayedPMs" }

        case on
        case off
    }

    enum EnablePassiveCaptcha: String, PickerEnum {
        static var enumName: String { "Enable passive captcha" }

        case on
        case off
    }

    enum EnableAttestationOnConfirmation: String, PickerEnum {
        static var enumName: String { "Enable attestation on confirmation" }

        case on
        case off
    }

    enum PaymentMethodSave: String, PickerEnum {
        static var enumName: String { "PaymentMethodSave" }

        case enabled
        case disabled
    }
    enum AllowRedisplayOverride: String, PickerEnum {
        static var enumName: String { "AllowRedisplayOverride" }

        case always
        case limited
        case unspecified
        case notSet
    }

    enum PaymentMethodRemove: String, PickerEnum {
        static var enumName: String { "PaymentMethodRemove" }

        case enabled
        case disabled
    }
    enum PaymentMethodRemoveLast: String, PickerEnum {
        static var enumName: String { "PaymentMethodRemoveLast" }

        case enabled
        case disabled
    }
    enum PaymentMethodRedisplay: String, PickerEnum {
        static var enumName: String { "PaymentMethodRedisplay" }

        case enabled
        case disabled
    }
    enum PaymentMethodAllowRedisplayFilters: String, PickerEnum {
        static var enumName: String { "PaymentMethodRedisplayFilters" }

        case always
        case limited
        case unspecified
        case unspecified_limited_always
        case notSet

        func arrayValue() -> [String]? {
            switch self {
            case .always:
                return ["always"]
            case .limited:
                return ["limited"]
            case .unspecified:
                return ["unspecified"]
            case .unspecified_limited_always:
                return ["unspecified", "limited", "always"]
            case .notSet:
                return nil
            }
        }
    }

    enum PaymentMethodSetAsDefault: String, PickerEnum {
        static let enumName: String = "PaymentMethodSetAsDefault"
        case enabled
        case disabled
    }

    enum DefaultBillingAddress: String, PickerEnum {
        static var enumName: String { "Default billing address" }

        case on
        case randomEmail
        case randomEmailNoPhone
        case customEmail
        case off
    }

    enum LinkPassthroughMode: String, PickerEnum {
        static var enumName: String { "Link passthrough mode" }

        case pm = "PaymentMethod"
        case passthrough
    }

    enum LinkEnabledMode: String, PickerEnum {
        static var enumName: String { "Enable Link" }

        case native
        case nativeWithAttestation = "attest"
        case web
        case off
    }

    enum UserOverrideCountry: String, PickerEnum {
        static var enumName: String { "UserOverrideCountry (debug only)" }

        case off
        case US
        case GB
    }

    enum BillingDetailsAttachDefaults: String, PickerEnum {
        static var enumName: String { "Attach defaults" }

        case on
        case off
    }

    enum BillingDetailsName: String, PickerEnum {
        static var enumName: String { "Name" }

        case automatic
        case never
        case always
    }
    enum BillingDetailsEmail: String, PickerEnum {
        static var enumName: String { "Email" }

        case automatic
        case never
        case always
    }
    enum BillingDetailsPhone: String, PickerEnum {
        static var enumName: String { "Phone" }

        case automatic
        case never
        case always
    }
    enum BillingDetailsAddress: String, PickerEnum {
        static var enumName: String { "Address" }

        case automatic
        case never
        case full
    }
    enum BillingDetailsAllowedCountries: String, PickerEnum {
        static var enumName: String { "Allowed Countries" }

        case all
        case usOnly = "us_only"
        case northAmerica = "north_america"
        case someEuropeanCountries = "some_european_countries"

        var countries: Set<String> {
            switch self {
            case .all:
                return []  // Empty set means all countries
            case .usOnly:
                return ["US"]
            case .northAmerica:
                return ["US", "CA", "MX"]
            case .someEuropeanCountries:
                return ["FR", "DE", "IT", "ES"]
            }
        }

        var displayName: String {
            switch self {
            case .all:
                return "All Countries"
            case .usOnly:
                return "US Only"
            case .northAmerica:
                return "North America (US, CA, MX)"
            case .someEuropeanCountries:
                return "Some Europe (FR, DE, IT, ES)"
            }
        }
    }
    enum Autoreload: String, PickerEnum {
        static var enumName: String { "Autoreload" }

        case on
        case off
    }
    enum ShakeAmbiguousViews: String, PickerEnum {
        static var enumName: String { "Shake Ambiguous Views" }

        case on
        case off
    }
    enum InstantDebitsIncentives: String, PickerEnum {
        static var enumName: String { "Instant Debits Incentives" }

        case on
        case off
    }
    enum FCLiteEnabled: String, PickerEnum {
        static var enumName: String { "FCLite enabled" }

        case on
        case off
    }
    enum ExternalPaymentMethods: String, PickerEnum {
        static let enumName: String = "External PMs"
        // Based on https://git.corp.stripe.com/stripe-internal/stripe-js-v3/blob/55d7fd10/src/externalPaymentMethods/constants.ts#L13
        static let allExternalPaymentMethods = [
            "external_aplazame",
            "external_atone",
            "external_au_easy_payment",
            "external_au_pay",
            "external_azupay",
            "external_bank_pay",
            "external_benefit",
            "external_bitcash",
            "external_bizum",
            "external_catch",
            "external_dapp",
            "external_dbarai",
            "external_divido",
            "external_famipay",
            "external_fawry",
            "external_fonix",
            "external_gcash",
            "external_grabpay_later",
            "external_interac",
            "external_iwocapay",
            "external_kbc",
            "external_knet",
            "external_laybuy",
            "external_line_pay",
            "external_merpay",
            "external_momo",
            "external_net_cash",
            "external_nexi_pay",
            "external_octopus",
            "external_oney",
            "external_paidy",
            "external_pay_easy",
            "external_payconiq",
            "external_paypal",
            "external_paypay",
            "external_paypo",
            "external_paysafecard",
            "external_picpay",
            "external_planpay",
            "external_pledg",
            "external_postepay",
            "external_postfinance",
            "external_rakuten_pay",
            "external_samsung_pay",
            "external_scalapay",
            "external_sezzle",
            "external_shopback_paylater",
            "external_softbank_carrier_payment",
            "external_tabby",
            "external_tng_ewallet",
            "external_toss_pay",
            "external_truelayer",
            "external_twint",
            "external_venmo",
            "external_walley",
            "external_webmoney",
            "external_younited_pay",
        ]

        case paypal
        case all
        case off

        var paymentMethods: [String]? {
            switch self {
            case .paypal:
                return ["external_paypal"]
            case .all:
                return ExternalPaymentMethods.allExternalPaymentMethods
            case .off:
                return nil
            }
        }
    }

    enum CustomPaymentMethods: String, PickerEnum {
        static let enumName: String = "CPMs"
        case on
        case onWithBDCC = "on w/ BDCC"
        case off
    }

    enum PreferredNetworksEnabled: String, PickerEnum {
        static let enumName: String = "Preferred Networks (CBC)"

        case on
        case off

        var displayName: String {
            switch self {
            case .on:
                return "[visa, cartesBancaires]"
            case .off:
                return "off"
            }
        }
    }
    enum RequireCVCRecollectionEnabled: String, PickerEnum {
        static let enumName: String = "Require CVC Recollection"
        case on
        case off
    }

    enum AllowsRemovalOfLastSavedPaymentMethodEnabled: String, PickerEnum {
        static let enumName: String = "allowsRemovalOfLastSavedPaymentMethod"
        case on
        case off
    }

    enum DisplaysMandateTextEnabled: String, PickerEnum {
        static let enumName: String = "displaysMandateText"
        case on
        case off
    }

    enum FormSheetAction: String, PickerEnum {
        static let enumName: String = "formSheetAction"
        case confirm
        case `continue`
    }

    enum RowSelectionBehavior: String, PickerEnum {
        static let enumName: String = "rowSelectionBehavior"
        case `default`
        case immediateAction
    }

    enum CardBrandAcceptance: String, PickerEnum {
        static let enumName: String = "cardBrandAcceptance"
        case all
        case blockAmEx
        case allowVisa
    }

    enum CardFundingAcceptance: String, PickerEnum {
        static let enumName: String = "fundingAcceptance"
        case all
        case creditOnly
        case debitOnly
    }

    enum ConfigurationStyle: String, PickerEnum {
        static let enumName: String = "Style"
        case automatic
        case alwaysLight
        case alwaysDark
    }
    enum PaymentMethodTermsDisplay: String, PickerEnum {
        static var enumName: String { "Card TermsDisplay" }
        case unset
        case automatic
        case never
    }

    enum OpensCardScannerAutomatically: String, PickerEnum {
        static let enumName: String = "opensCardScannerAutomatically"
        case on
        case off
    }

    var uiStyle: UIStyle
    var layout: Layout
    var mode: Mode
    var style: ConfigurationStyle
    var customerKeyType: CustomerKeyType
    var integrationType: IntegrationType
    var confirmationMode: ConfirmationMode
    var customerMode: CustomerMode
    var currency: Currency
    var amount: Amount
    var merchantCountryCode: MerchantCountry
    // For testing purposes only; keys should typically not be defined on the client
    var customSecretKey: String?
    var customPublishableKey: String?
    var apmsEnabled: APMSEnabled
    var supportedPaymentMethods: String?
    var paymentMethodOptionsSetupFutureUsage: PaymentMethodOptionsSetupFutureUsage

    var shippingInfo: ShippingInfo
    var applePayEnabled: ApplePayEnabled
    var applePayButtonType: ApplePayButtonType
    var allowsDelayedPMs: AllowsDelayedPMs
    var enablePassiveCaptcha: EnablePassiveCaptcha
    var enableAttestationOnConfirmation: EnableAttestationOnConfirmation
    var paymentMethodSave: PaymentMethodSave
    var allowRedisplayOverride: AllowRedisplayOverride
    var paymentMethodRemove: PaymentMethodRemove
    var paymentMethodRemoveLast: PaymentMethodRemoveLast
    var paymentMethodRedisplay: PaymentMethodRedisplay
    var paymentMethodAllowRedisplayFilters: PaymentMethodAllowRedisplayFilters
    var paymentMethodSetAsDefault: PaymentMethodSetAsDefault
    var defaultBillingAddress: DefaultBillingAddress
    var customEmail: String?
    var linkPassthroughMode: LinkPassthroughMode
    var linkEnabledMode: LinkEnabledMode
    var linkDisplay: LinkDisplay
    var userOverrideCountry: UserOverrideCountry
    var customCtaLabel: String?
    var paymentMethodConfigurationId: String?
    var checkoutEndpoint: String
    var autoreload: Autoreload
    var shakeAmbiguousViews: ShakeAmbiguousViews
    var instantDebitsIncentives: InstantDebitsIncentives
    var fcLiteEnabled: FCLiteEnabled
    var externalPaymentMethods: ExternalPaymentMethods
    var customPaymentMethods: CustomPaymentMethods
    var preferredNetworksEnabled: PreferredNetworksEnabled
    var requireCVCRecollection: RequireCVCRecollectionEnabled
    var allowsRemovalOfLastSavedPaymentMethod: AllowsRemovalOfLastSavedPaymentMethodEnabled

    var attachDefaults: BillingDetailsAttachDefaults
    var collectName: BillingDetailsName
    var collectEmail: BillingDetailsEmail
    var collectPhone: BillingDetailsPhone
    var collectAddress: BillingDetailsAddress
    var allowedCountries: BillingDetailsAllowedCountries
    var formSheetAction: FormSheetAction
    var embeddedViewDisplaysMandateText: DisplaysMandateTextEnabled
    var rowSelectionBehavior: RowSelectionBehavior
    var cardBrandAcceptance: CardBrandAcceptance
    var cardFundingAcceptance: CardFundingAcceptance
    var opensCardScannerAutomatically: OpensCardScannerAutomatically
    var termsDisplay: PaymentMethodTermsDisplay

    static func defaultValues() -> PaymentSheetTestPlaygroundSettings {
        return PaymentSheetTestPlaygroundSettings(
            uiStyle: .paymentSheet,
            layout: .automatic,
            mode: .payment,
            style: .automatic,
            customerKeyType: .customerSession,
            integrationType: .normal,
            confirmationMode: .confirmationToken,
            customerMode: .guest,
            currency: .usd,
            amount: ._5099,
            merchantCountryCode: .US,
            apmsEnabled: .on,
            paymentMethodOptionsSetupFutureUsage: PaymentMethodOptionsSetupFutureUsage.defaultValues(),
            shippingInfo: .off,
            applePayEnabled: .on,
            applePayButtonType: .buy,
            allowsDelayedPMs: .on,
            enablePassiveCaptcha: .on,
            enableAttestationOnConfirmation: .on,
            paymentMethodSave: .enabled,
            allowRedisplayOverride: .notSet,
            paymentMethodRemove: .enabled,
            paymentMethodRemoveLast: .enabled,
            paymentMethodRedisplay: .enabled,
            paymentMethodAllowRedisplayFilters: .always,
            paymentMethodSetAsDefault: .disabled,
            defaultBillingAddress: .off,
            customEmail: nil,
            linkPassthroughMode: .passthrough,
            linkEnabledMode: .native,
            linkDisplay: .automatic,
            userOverrideCountry: .off,
            customCtaLabel: nil,
            paymentMethodConfigurationId: nil,
            checkoutEndpoint: Self.defaultCheckoutEndpoint,
            autoreload: .on,
            shakeAmbiguousViews: .off,
            instantDebitsIncentives: .off,
            fcLiteEnabled: .off,
            externalPaymentMethods: .off,
            customPaymentMethods: .off,
            preferredNetworksEnabled: .off,
            requireCVCRecollection: .off,
            allowsRemovalOfLastSavedPaymentMethod: .on,
            attachDefaults: .off,
            collectName: .automatic,
            collectEmail: .automatic,
            collectPhone: .automatic,
            collectAddress: .automatic,
            allowedCountries: .all,
            formSheetAction: .continue,
            embeddedViewDisplaysMandateText: .on,
            rowSelectionBehavior: .default,
            cardBrandAcceptance: .all,
            cardFundingAcceptance: .all,
            opensCardScannerAutomatically: .off,
            termsDisplay: .unset
        )
    }

    static let nsUserDefaultsKey = "PaymentSheetTestPlaygroundSettings"
    static let nsUserDefaultsCustomerIDKey = "PaymentSheetTestPlaygroundCustomerId"
    static let nsUserDefaultsAppearanceKey = "PaymentSheetTestPlaygroundAppearance"

    static let baseEndpoint = "https://stp-mobile-playground-backend-v7.stripedemos.com"
    static var endpointSelectorEndpoint: String {
        return "\(baseEndpoint)/endpoints"
    }
    static var defaultCheckoutEndpoint: String {
        return "\(baseEndpoint)/checkout"
    }
    static var confirmEndpoint: String {
        return "\(baseEndpoint)/confirm_intent"
    }

    var base64Data: String {
        let jsonData = try! JSONEncoder().encode(self)
        return jsonData.base64EncodedString()
    }

    var base64URL: URL {
        URL(string: "stp-paymentsheet-playground://?\(base64Data)")!
    }

    static func fromBase64<T: Decodable>(base64: String, className: T.Type) -> T? {
        if let base64Data = base64.data(using: .utf8),
           let data = Data(base64Encoded: base64Data),
           let decodedObject = try? JSONDecoder().decode(className.self, from: data) {
            return decodedObject
        }
        return nil
    }
}

protocol PickerEnum: Codable, CaseIterable, Identifiable, Hashable where AllCases: RandomAccessCollection {
    static var enumName: String { get }
    var displayName: String { get }
}

extension PickerEnum {
    var id: Self { self }
}

extension RawRepresentable where RawValue == String {
    var displayName: String { self.rawValue }
}
