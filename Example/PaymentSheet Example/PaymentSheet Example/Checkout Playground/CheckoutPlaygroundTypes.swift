//
//  CheckoutPlaygroundTypes.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import Foundation
import PassKit
@_spi(STP) import StripePaymentSheet

extension ExpressCheckoutElement.ApplePayConfiguration.Display: CaseIterable, Identifiable {
    public static var allCases: [Self] { [.automatic, .never] }
    public var id: String { rawValue }
}

extension ExpressCheckoutElement.LinkConfiguration.Display: CaseIterable, Identifiable {
    public static var allCases: [Self] { [.automatic, .never] }
    public var id: String { rawValue }
}

extension ExpressCheckoutElement.Appearance.ButtonTheme: CaseIterable, Identifiable {
    public static var allCases: [Self] { [.automatic, .light, .dark] }
    public var id: String { rawValue }
}

enum CheckoutPlayground {
    enum ApplePayButtonType: String, CaseIterable, Identifiable, Codable {
        case plain
        case buy
        case setup
        case checkout

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .plain: return "Plain"
            case .buy: return "Buy"
            case .setup: return "Set Up"
            case .checkout: return "Checkout"
            }
        }

        var pkPaymentButtonType: PKPaymentButtonType {
            switch self {
            case .plain: return .plain
            case .buy: return .buy
            case .setup: return .setUp
            case .checkout: return .checkout
            }
        }
    }

    enum ExpressCheckoutPaymentMethodOrder: String, CaseIterable, Identifiable, Codable {
        case dynamic
        case applePayFirst
        case linkFirst

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .dynamic: return "Dynamic"
            case .applePayFirst: return "Apple Pay first"
            case .linkFirst: return "Link first"
            }
        }

        var paymentMethodOrder: [String]? {
            switch self {
            case .dynamic: return nil
            case .applePayFirst: return ["apple_pay", "link"]
            case .linkFirst: return ["link", "apple_pay"]
            }
        }
    }

    enum LinkMode: String, CaseIterable, Identifiable, Codable {
        case native
        case web

        var id: String { rawValue }
        var displayName: String { rawValue.capitalized }
    }

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
                return "https://stp-mobile-playground-backend-v7.stripedemos.com"
            case .localhost:
                return "http://127.0.0.1:8081"
            case .manual:
                return nil
            }
        }

        static func from(endpoint: String) -> Self {
            let endpoint = normalizedBaseURL(from: endpoint)
            if endpoint == Self.hosted.endpoint {
                return .hosted
            }
            if endpoint == Self.localhost.endpoint {
                return .localhost
            }
            return .manual
        }

        static func normalizedBaseURL(from endpoint: String) -> String {
            var endpoint = endpoint
            while endpoint.hasSuffix("/") {
                endpoint.removeLast()
            }
            for legacyPath in ["/checkout_session", "/create_checkout_session"] where endpoint.hasSuffix(legacyPath) {
                endpoint.removeLast(legacyPath.count)
                break
            }
            return endpoint
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

    enum EmailSource: String, CaseIterable, Identifiable, Codable {
        case none
        case checkoutSession
        case customer
        case local

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .none: return "None"
            case .checkoutSession: return "Server — Checkout Session"
            case .customer: return "Server — Customer"
            case .local: return "Local"
            }
        }

        var isServer: Bool { self == .checkoutSession || self == .customer }
    }

    struct EmailSettings: Codable {
        var source: EmailSource = .checkoutSession
        var value = "jenny@example.com"

        var email: String? {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return source == .none || trimmed.isEmpty ? nil : trimmed
        }

        var localDefaultEmail: String? { source == .local ? email : nil }
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

        static let zeroAmount = [
            LineItemConfig(name: "Free T-Shirt", unitAmount: 0, quantity: 1),
        ]
    }

    enum CartScenario: String, CaseIterable, Codable, Identifiable {
        case standard
        case zeroAmount = "zero_amount"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .standard:
                return "Standard cart"
            case .zeroAmount:
                return "$0 cart"
            }
        }

        var lineItems: [LineItemConfig] {
            switch self {
            case .standard:
                return LineItemConfig.defaults
            case .zeroAmount:
                return LineItemConfig.zeroAmount
            }
        }
    }

    enum ExpressCheckoutElementButtonLayoutLimit: String, CaseIterable, Identifiable {
        case automatic
        case one
        case two

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .automatic: return "automatic"
            case .one: return "1"
            case .two: return "2"
            }
        }

        var intValue: Int? {
            switch self {
            case .automatic: return nil
            case .one: return 1
            case .two: return 2
            }
        }

        init(intValue: Int?) {
            switch intValue {
            case 1: self = .one
            case 2: self = .two
            default: self = .automatic
            }
        }
    }

    struct ExpressCheckoutElementSettings: Codable {
        var isEnabled: Bool
        var applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display
        var applePayButtonType: ApplePayButtonType
        var linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display
        var shippingAddressRequired: Bool
        var paymentMethodOrder: ExpressCheckoutPaymentMethodOrder
        var appearance: ExpressCheckoutElement.Appearance

        init(
            isEnabled: Bool = true,
            applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display = .automatic,
            applePayButtonType: ApplePayButtonType = .plain,
            linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display = .automatic,
            shippingAddressRequired: Bool = false,
            paymentMethodOrder: ExpressCheckoutPaymentMethodOrder = .dynamic,
            appearance: ExpressCheckoutElement.Appearance = .init()
        ) {
            self.isEnabled = isEnabled
            self.applePayDisplay = applePayDisplay
            self.applePayButtonType = applePayButtonType
            self.linkDisplay = linkDisplay
            self.shippingAddressRequired = shippingAddressRequired
            self.paymentMethodOrder = paymentMethodOrder
            self.appearance = appearance
        }

        private enum CodingKeys: String, CodingKey {
            case isEnabled
            case applePayDisplay
            case applePayButtonType
            case linkDisplay
            case shippingAddressRequired
            case paymentMethodOrder
            case buttonTheme
            case maxColumns
            case maxRows
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var appearance = ExpressCheckoutElement.Appearance()
            appearance.buttonTheme = try container.decodeIfPresent(String.self, forKey: .buttonTheme)
                .flatMap(ExpressCheckoutElement.Appearance.ButtonTheme.init(rawValue:)) ?? .automatic
            appearance.buttonLayout.maxColumns = try container.decodeIfPresent(Int.self, forKey: .maxColumns)
            appearance.buttonLayout.maxRows = try container.decodeIfPresent(Int.self, forKey: .maxRows)

            self.init(
                isEnabled: try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true,
                applePayDisplay: try container.decodeIfPresent(String.self, forKey: .applePayDisplay)
                    .flatMap(ExpressCheckoutElement.ApplePayConfiguration.Display.init(rawValue:)) ?? .automatic,
                applePayButtonType: try container.decodeIfPresent(ApplePayButtonType.self, forKey: .applePayButtonType) ?? .plain,
                linkDisplay: try container.decodeIfPresent(String.self, forKey: .linkDisplay)
                    .flatMap(ExpressCheckoutElement.LinkConfiguration.Display.init(rawValue:)) ?? .automatic,
                shippingAddressRequired: try container.decodeIfPresent(Bool.self, forKey: .shippingAddressRequired) ?? false,
                paymentMethodOrder: try container.decodeIfPresent(ExpressCheckoutPaymentMethodOrder.self, forKey: .paymentMethodOrder) ?? .dynamic,
                appearance: appearance
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isEnabled, forKey: .isEnabled)
            try container.encode(applePayDisplay.rawValue, forKey: .applePayDisplay)
            try container.encode(applePayButtonType, forKey: .applePayButtonType)
            try container.encode(linkDisplay.rawValue, forKey: .linkDisplay)
            try container.encode(shippingAddressRequired, forKey: .shippingAddressRequired)
            try container.encode(paymentMethodOrder, forKey: .paymentMethodOrder)
            try container.encode(appearance.buttonTheme.rawValue, forKey: .buttonTheme)
            try container.encodeIfPresent(appearance.buttonLayout.maxColumns, forKey: .maxColumns)
            try container.encodeIfPresent(appearance.buttonLayout.maxRows, forKey: .maxRows)
        }
    }

    struct Settings: Codable {

        var uiFramework: UIFramework = .swiftUI
        var integrationType: IntegrationType = .flowController
        var expressCheckoutElement = ExpressCheckoutElementSettings()
        var linkMode: LinkMode = .native
        var currency: Currency = .usd
        var customerType: CustomerType = .guest
        var email: EmailSettings? = .init()
        var cartScenario: CartScenario = .standard
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
