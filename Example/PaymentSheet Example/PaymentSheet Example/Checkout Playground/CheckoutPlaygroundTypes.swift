//
//  CheckoutPlaygroundTypes.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import Foundation
import PassKit
@_spi(STP) import StripePaymentSheet

enum CheckoutPlayground {
    enum EndpointOption: String, CaseIterable, Identifiable {
        case hosted
        case localhost
        case manual

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .hosted:
                return "Hosted"
            case .localhost:
                return "Localhost"
            case .manual:
                return "Manual"
            }
        }

        var endpoint: String? {
            switch self {
            case .hosted:
                return "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout_session"
            case .localhost:
                return "http://127.0.0.1:8081/checkout_session"
            case .manual:
                return nil
            }
        }

        static func from(endpoint: String) -> Self {
            if endpoint == Self.hosted.endpoint {
                return .hosted
            }
            if endpoint == Self.localhost.endpoint {
                return .localhost
            }
            return .manual
        }
    }

    enum Currency: String, CaseIterable, Identifiable {
        case usd
        case eur
        case gbp
        case cad
        case aud
        case jpy

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .usd, .cad, .aud:
                return "$"
            case .eur:
                return "€"
            case .gbp:
                return "£"
            case .jpy:
                return "¥"
            }
        }

        var isZeroDecimal: Bool {
            return self == .jpy
        }
    }

    enum CustomerType: String, CaseIterable, Identifiable {
        case returning
        case new
        case guest

        var id: String { rawValue }
    }

    enum AdaptivePricingCountry: String, CaseIterable, Identifiable {
        case none
        case us
        case fr
        case de
        case jp
        case gb
        case br

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "None"
            case .us: return "US"
            case .fr: return "FR"
            case .de: return "DE"
            case .jp: return "JP"
            case .gb: return "GB"
            case .br: return "BR"
            }
        }
    }

    enum BillingAddressCollection: String, CaseIterable, Identifiable {
        case automatic
        case required

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .automatic: return "Auto"
            case .required: return "Required"
            }
        }
    }

    enum IntegrationType: String, CaseIterable, Identifiable {
        case flowController
        case embedded
        case disabled

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .flowController: return "sheet"
            case .embedded: return "view"
            case .disabled: return "none"
            }
        }
    }

    enum ExpressCheckoutElementOption: String, CaseIterable, Identifiable {
        case disabled
        case enabled

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .disabled: return "none"
            case .enabled: return "show"
            }
        }
    }

    enum WalletVisibilityOption: String, CaseIterable, Identifiable {
        case automatic
        case always
        case never

        var id: String { rawValue }

        var displayName: String { rawValue }

        var walletVisibility: ExpressCheckoutElement.Configuration.WalletVisibility {
            switch self {
            case .automatic: return .automatic
            case .always: return .always
            case .never: return .never
            }
        }
    }

    enum LinkDisplayOption: String, CaseIterable, Identifiable {
        case automatic
        case never

        var id: String { rawValue }

        var displayName: String { rawValue }

        var linkDisplay: Checkout.LinkConfiguration.Display {
            switch self {
            case .automatic: return .automatic
            case .never: return .never
            }
        }
    }

    enum ApplePayButtonTypeOption: String, CaseIterable, Identifiable {
        case plain
        case buy
        case checkout
        case subscribe
        case donate

        var id: String { rawValue }

        var displayName: String { rawValue }

        var pkButtonType: PKPaymentButtonType {
            switch self {
            case .plain: return .plain
            case .buy: return .buy
            case .checkout: return .checkout
            case .subscribe: return .subscribe
            case .donate: return .donate
            }
        }
    }

    struct LineItemConfig: Identifiable {
        let id = UUID()
        var name: String
        var unitAmount: Int
        var quantity: Int

        static let defaults: [LineItemConfig] = [
            LineItemConfig(name: "Classic T-Shirt", unitAmount: 3500, quantity: 2),
            LineItemConfig(name: "Zip-Up Hoodie", unitAmount: 5000, quantity: 1),
        ]
    }
}
