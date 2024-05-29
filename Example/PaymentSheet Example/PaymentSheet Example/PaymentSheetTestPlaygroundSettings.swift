//
//  PaymentSheetTestPlaygroundSettings.swift
//  PaymentSheet Example
//
//  Created by David Estes on 5/31/23.
//

import Foundation

struct PaymentSheetTestPlaygroundSettings: Codable, Equatable {
    enum UIStyle: String, PickerEnum {
        static var enumName: String { "UI" }

        case paymentSheet
        case flowController
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
            }
        }
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
        static var enumName: String { "MerchantCountry" }

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
    }

    enum APMSEnabled: String, PickerEnum {
        static var enumName: String { "Automatic PMs" }

        case on
        case off
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
    }

    enum ApplePayButtonType: String, PickerEnum {
        static var enumName: String { "Pay button" }

        case plain
        case buy
        case setup
        case checkout
    }

    enum AllowsDelayedPMs: String, PickerEnum {
        static var enumName: String { "allowsDelayedPMs" }

        case on
        case off
    }
    enum PaymentMethodRemove: String, PickerEnum {
        static var enumName: String { "PaymentMethodRemove" }

        case enabled
        case disabled
    }
    enum PaymentMethodSave: String, PickerEnum {
        static var enumName: String { "PaymentMethodSave" }

        case enabled
        case disabled
    }
    enum PaymentMethodRedisplay: String, PickerEnum {
        static var enumName: String { "PaymentMethodRedisplay" }

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

    enum LinkEnabled: String, PickerEnum {
        static var enumName: String { "Link" }

        case on
        case off
    }

    enum UserOverrideCountry: String, PickerEnum {
        static var enumName: String { "UserOverrideCountry (debug only)" }

        case off
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
    enum Autoreload: String, PickerEnum {
        static var enumName: String { "Autoreload" }

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
            "external_billie",
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
            "external_kriya",
            "external_laybuy",
            "external_line_pay",
            "external_merpay",
            "external_momo",
            "external_mondu",
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
            "external_satispay",
            "external_scalapay",
            "external_sequra",
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

    var uiStyle: UIStyle
    var layout: Layout
    var mode: Mode
    var customerKeyType: CustomerKeyType
    var integrationType: IntegrationType
    var customerMode: CustomerMode
    var currency: Currency
    var merchantCountryCode: MerchantCountry
    var apmsEnabled: APMSEnabled
    var supportedPaymentMethods: String?

    var shippingInfo: ShippingInfo
    var applePayEnabled: ApplePayEnabled
    var applePayButtonType: ApplePayButtonType
    var allowsDelayedPMs: AllowsDelayedPMs
    var paymentMethodRemove: PaymentMethodRemove
    var paymentMethodSave: PaymentMethodSave
    var paymentMethodRedisplay: PaymentMethodRedisplay
    var defaultBillingAddress: DefaultBillingAddress
    var customEmail: String?
    var linkEnabled: LinkEnabled
    var userOverrideCountry: UserOverrideCountry
    var customCtaLabel: String?
    var paymentMethodConfigurationId: String?
    var checkoutEndpoint: String?
    var autoreload: Autoreload
    var externalPaymentMethods: ExternalPaymentMethods
    var preferredNetworksEnabled: PreferredNetworksEnabled
    var requireCVCRecollection: RequireCVCRecollectionEnabled
    var allowsRemovalOfLastSavedPaymentMethod: AllowsRemovalOfLastSavedPaymentMethodEnabled

    var attachDefaults: BillingDetailsAttachDefaults
    var collectName: BillingDetailsName
    var collectEmail: BillingDetailsEmail
    var collectPhone: BillingDetailsPhone
    var collectAddress: BillingDetailsAddress

    static func defaultValues() -> PaymentSheetTestPlaygroundSettings {
        return PaymentSheetTestPlaygroundSettings(
            uiStyle: .paymentSheet,
            layout: .horizontal,
            mode: .payment,
            customerKeyType: .legacy,
            integrationType: .normal,
            customerMode: .guest,
            currency: .usd,
            merchantCountryCode: .US,
            apmsEnabled: .on,
            shippingInfo: .off,
            applePayEnabled: .on,
            applePayButtonType: .buy,
            allowsDelayedPMs: .on,
            paymentMethodRemove: .enabled,
            paymentMethodSave: .enabled,
            paymentMethodRedisplay: .enabled,
            defaultBillingAddress: .off,
            customEmail: nil,
            linkEnabled: .off,
            userOverrideCountry: .off,
            customCtaLabel: nil,
            paymentMethodConfigurationId: nil,
            checkoutEndpoint: Self.defaultCheckoutEndpoint,
            autoreload: .on,
            externalPaymentMethods: .off,
            preferredNetworksEnabled: .off,
            requireCVCRecollection: .off,
            allowsRemovalOfLastSavedPaymentMethod: .on,
            attachDefaults: .off,
            collectName: .automatic,
            collectEmail: .automatic,
            collectPhone: .automatic,
            collectAddress: .automatic)
    }

    static let nsUserDefaultsKey = "PaymentSheetTestPlaygroundSettings"
    static let nsUserDefaultsCustomerIDKey = "PaymentSheetTestPlaygroundCustomerId"

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
