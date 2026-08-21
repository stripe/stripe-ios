//
//  CheckoutPlaygroundTypes.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import Foundation
@_spi(STP) import StripePaymentSheet

enum CheckoutPlayground {
    enum UIFramework: String, CaseIterable, Identifiable, Codable {

        case swiftUI
        case uiKit

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .swiftUI: return "SwiftUI"
            case .uiKit: return "UIKit"
            }
        }
    }

    enum EndpointOption: String, CaseIterable, Identifiable, Codable {
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

    enum Currency: String, CaseIterable, Identifiable, Codable {
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

    enum CustomerType: String, CaseIterable, Identifiable, Codable {
        case returning
        case new
        case guest

        var id: String { rawValue }
    }

    enum AdaptivePricingCountry: String, CaseIterable, Identifiable, Codable {
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
            case .none: return "No Override"
            case .us: return "United States (US)"
            case .fr: return "France (FR)"
            case .de: return "Germany (DE)"
            case .jp: return "Japan (JP)"
            case .gb: return "United Kingdom (GB)"
            case .br: return "Brazil (BR)"
            }
        }
    }

    enum BillingAddressCollection: String, CaseIterable, Identifiable, Codable {
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

    enum DefaultShippingAddressOption: String, CaseIterable, Identifiable, Codable {

        case none
        case usTestAddress
        case custom

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "No address"
            case .usTestAddress: return "US test address"
            case .custom: return "Custom"
            }
        }
    }

    struct DefaultShippingAddress: Equatable, Codable {

        var name: String
        var line1: String
        var line2: String
        var city: String
        var state: String
        var postalCode: String
        var country: String

        static let usTestAddress = DefaultShippingAddress(
            name: "Jenny Rosen",
            line1: "510 Townsend St",
            line2: "",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103",
            country: "US"
        )

        var checkoutShippingDetails: CheckoutController.Configuration.Defaults.ShippingDetails {
            var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
            shippingDetails.name = name
            shippingDetails.address = CheckoutController.Address(
                country: country,
                line1: line1,
                line2: line2,
                city: city,
                state: state,
                postalCode: postalCode
            )
            return shippingDetails
        }
    }

    enum IntegrationType: String, CaseIterable, Identifiable, Codable {
        case flowController
        case embedded
        case eceOnly

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .flowController: return "sheet"
            case .embedded: return "view"
            case .eceOnly: return "ece only"
            }
        }
    }

    enum ExpressCheckoutElementOption: String, CaseIterable, Identifiable, Codable {
        case show
        case hide

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .show: return "show"
            case .hide: return "hide"
            }
        }
    }

    struct LineItemConfig: Identifiable, Codable {

        let id: UUID
        var name: String
        var unitAmount: Int
        var quantity: Int

        init(
            id: UUID = UUID(),
            name: String,
            unitAmount: Int,
            quantity: Int
        ) {
            self.id = id
            self.name = name
            self.unitAmount = unitAmount
            self.quantity = quantity
        }

        static let defaults: [LineItemConfig] = [
            LineItemConfig(name: "Classic T-Shirt", unitAmount: 3500, quantity: 2),
            LineItemConfig(name: "Zip-Up Hoodie", unitAmount: 5000, quantity: 1),
        ]
    }

    struct Settings: Codable {

        var uiFramework: UIFramework = .swiftUI
        var integrationType: IntegrationType = .flowController
        var expressCheckoutElementOption: ExpressCheckoutElementOption = .show
        var currency: Currency = .usd
        var customerType: CustomerType = .guest
        var lineItems: [LineItemConfig] = LineItemConfig.defaults
        var shippingAddressCollection = true
        var defaultShippingAddressOption: DefaultShippingAddressOption = .none
        var customDefaultShippingAddress = DefaultShippingAddress.usTestAddress
        var billingAddressCollection: BillingAddressCollection = .automatic
        var automaticTax = true
        var checkoutSessionPaymentMethodSave = true
        var checkoutSessionPaymentMethodRemove = true
        var adaptivePricingCountry: AdaptivePricingCountry = .none
        var automaticPaymentMethods = false
        var paymentMethodTypes: Set<String> = ["card"]
        var currencySelectorAppearance = CurrencySelectorElement.Appearance()
        var checkoutEndpointOption: EndpointOption = .hosted
        var checkoutEndpoint = EndpointOption.hosted.endpoint ?? ""
        var delayPaymentPagesRequests = false

        static let nsUserDefaultsKey = "CheckoutPlaygroundSettings"
    }
}
