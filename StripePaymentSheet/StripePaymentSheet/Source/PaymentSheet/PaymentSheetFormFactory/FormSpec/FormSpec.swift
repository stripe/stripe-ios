//
//  FormSpec.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/11/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

/// A decodable representation that can used to construct a `FormElement`
struct FormSpec: Decodable {
    let type: String
    let async: Bool?
    let fields: [FieldSpec]
    let selectorIcon: DownloadableImageSpec?

    enum FieldSpec: Decodable, Equatable {
        case name(NameFieldSpec)
        case email(BaseFieldSpec)
        case selector(SelectorSpec)
        case billing_address(BillingAddressSpec)
        case country(CountrySpec)

        case affirm_header

        case klarna_header
        case klarna_country(BaseFieldSpec)

        case au_becs_bsb_number(BaseFieldSpec)
        case au_becs_account_number(BaseFieldSpec)
        case au_becs_mandate

        case afterpay_header

        case iban(BaseFieldSpec)
        case sepa_mandate

        case placeholder(PlaceholderSpec)
        case native_payment_method_form(NativePaymentMethodFormSpec)
        case native_mandate(NativeMandateSpec)

        case unknown(String)

        private enum CodingKeys: String, CodingKey {
            case type
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let field_type = try container.decode(String.self, forKey: .type)

            switch field_type {
            case "name":
                self = try .name(NameFieldSpec(from: decoder))
            case "email":
                self = try .email(BaseFieldSpec(from: decoder))
            case "selector":
                self = try .selector(SelectorSpec(from: decoder))
            case "billing_address":
                self = try .billing_address(BillingAddressSpec(from: decoder))
            case "country":
                self = try .country(CountrySpec(from: decoder))
            case "affirm_header":
                self = .affirm_header
            case "klarna_header":
                self = .klarna_header
            case "klarna_country":
                self = try .klarna_country(BaseFieldSpec(from: decoder))
            case "au_becs_bsb_number":
                self = try .au_becs_bsb_number(BaseFieldSpec(from: decoder))
            case "au_becs_account_number":
                self = try .au_becs_account_number(BaseFieldSpec(from: decoder))
            case "au_becs_mandate":
                self = .au_becs_mandate
            case "afterpay_header":
                self = .afterpay_header
            case "iban":
                self = try .iban(BaseFieldSpec(from: decoder))
            case "sepa_mandate":
                self = .sepa_mandate
            case "placeholder":
                self = try .placeholder(PlaceholderSpec(from: decoder))
            case "native_payment_method_form":
                self = try .native_payment_method_form(NativePaymentMethodFormSpec(from: decoder))
            case "native_mandate":
                self = try .native_mandate(NativeMandateSpec(from: decoder))
            default:
                self = .unknown(field_type)
            }
        }
    }

    struct DownloadableImageSpec: Decodable {
        let lightThemePng: String
        let darkThemePng: String?
    }
}

extension FormSpec {
    struct BaseFieldSpec: Decodable, Equatable {
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String: String]?
    }

    struct NameFieldSpec: Decodable, Equatable {
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String: String]?
        /// An optional localizedId to control the label
        let translationId: LocalizedString?
    }

    struct SelectorSpec: Decodable, Equatable {
        struct PropertyItemSpec: Decodable, Equatable {
            /// The localized text to display for this item in the dropdown
            let displayText: String
            /// The value to send to the Stripe API if the customer selects this dropdown item
            let apiValue: String?
        }

        /// The dropdown's label
        let translationId: LocalizedString
        /// The list of items to display in the dropdown
        let items: [PropertyItemSpec]
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String: String]?
    }

    struct BillingAddressSpec: Decodable, Equatable {
        /// The list of countries to be displayed for this component
        let allowedCountryCodes: [String]?
    }

    struct CountrySpec: Decodable, Equatable {
        /// A form URL encoded key, whose value is `PropertyItemSpec.apiValue`
        let apiPath: [String: String]?

        /// The list of countries to be displayed for this component
        let allowedCountryCodes: [String]?
    }

    struct PlaceholderSpec: Decodable, Equatable {
        let field: PlaceholderField

        enum CodingKeys: String, CodingKey {
            case field = "for"
        }

        enum PlaceholderField: String, Decodable, Equatable {
            case name
            case email
            case phone
            case billingAddress = "billing_address"
            case billingAddressWithoutCountry = "billing_address_without_country"
            case unknown

            init(from decoder: Decoder) throws {
                self = try .init(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
            }
        }
    }

    struct NativePaymentMethodFormSpec: Decodable, Equatable {
        let formType: FormType
        let subtitle: String?
        let disableBillingDetailCollection: Bool?

        enum FormType: String, Decodable, Equatable {
            case card
            case usBankAccount = "us_bank_account"
            case instantDebits = "instant_debits"
            case externalPaymentMethod = "external_payment_method"
            case bacsDebit = "bacs_debit"
            case blik
            case konbini
            case boleto
        }
    }

    struct NativeMandateSpec: Decodable, Equatable {
        let mandateType: MandateType
        let setupFutureUsageRequired: Bool?

        enum MandateType: String, Decodable, Equatable {
            case cashApp = "cashapp"
            case paypal
            case revolutPay = "revolut_pay"
            case amazonPay = "amazon_pay"
            case satispay
            case twint
            case sepa
            case klarna
        }
    }
}

extension FormSpec {
    enum LocalizedString: String, Decodable {
        case ideal_bank = "upe.labels.ideal.bank"
        case eps_bank = "upe.labels.eps.bank"
        case p24_bank = "upe.labels.p24.bank"
        case fpx_bank = "upe.labels.fpx.bank"

        case nameLabel_given = "upe.labels.name.given"
        case nameLabel_family = "upe.labels.name.family"
        case nameLabel_full = "upe.labels.name.full"
        case nameLabel_onAccount = "upe.labels.name.onAccount"

        var localizedValue: String {
            switch self {
            case .ideal_bank:
                return String.Localized.ideal_bank
            case .eps_bank:
                return STPLocalizedString("EPS Bank", "Label title for EPS Bank")
            case .p24_bank:
                return STPLocalizedString("Przelewy24 Bank", "Label title for Przelewy24 Bank")
            case .fpx_bank:
                return STPLocalizedString("FPX Bank", "Select a bank dropdown for FPX")
            case .nameLabel_given:
                return String.Localized.given_name
            case .nameLabel_family:
                return String.Localized.family_name
            case .nameLabel_full:
                return String.Localized.name
            case .nameLabel_onAccount:
                return String.Localized.nameOnAccount
            }
        }
    }
}
