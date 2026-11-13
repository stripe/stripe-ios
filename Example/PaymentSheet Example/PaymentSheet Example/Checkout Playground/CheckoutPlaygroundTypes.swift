//
//  CheckoutPlaygroundTypes.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import Foundation
import PassKit
@_spi(InternalOnlyAPI) import StripePaymentSheet

extension ExpressCheckoutElement.Configuration.LinkConfiguration.Display: CaseIterable, Identifiable {
    public static var allCases: [Self] { [.automatic, .never] }
    public var id: String { rawValue }
}

extension ExpressCheckoutElement.Configuration.Appearance.ButtonTheme: CaseIterable, Identifiable {
    public static var allCases: [Self] { [.automatic, .light, .dark] }
    public var id: String { rawValue }
}

enum CheckoutPlayground {
    enum PaymentElementApplePayDisplay: String, CaseIterable, Identifiable, Codable {
        case automatic
        case never

        var id: String { rawValue }

        var sdkValue: PaymentElement.Configuration.ApplePayConfiguration.Display {
            switch self {
            case .automatic: return .automatic
            case .never: return .never
            }
        }
    }

    enum ApplePayButtonType: String, CaseIterable, Identifiable, Codable {
        /// Leaves `buttonType` as `nil` so the SDK picks its default.
        case unset
        case plain
        case buy
        case setup
        case checkout

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .unset: return "nil"
            case .plain: return "Plain"
            case .buy: return "Buy"
            case .setup: return "Set Up"
            case .checkout: return "Checkout"
            }
        }

        var pkPaymentButtonType: PKPaymentButtonType? {
            switch self {
            case .unset: return nil
            case .plain: return .plain
            case .buy: return .buy
            case .setup: return .setUp
            case .checkout: return .checkout
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
            case .checkoutSession: return "Server — Session"
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

    enum DefaultAddressOption: String, CaseIterable, Identifiable, Codable {

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

    struct DefaultAddress: Equatable, Codable {

        var name: String
        var line1: String
        var line2: String
        var city: String
        var state: String
        var postalCode: String
        var country: String

        static let usTestAddress = DefaultAddress(
            name: "Jenny Rosen",
            line1: "510 Townsend St",
            line2: "",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103",
            country: "US"
        )

        var checkoutShippingDetails: CheckoutElementsController.Configuration.Defaults.ShippingDetails {
            var shippingDetails = CheckoutElementsController.Configuration.Defaults.ShippingDetails()
            shippingDetails.name = name
            shippingDetails.address = CheckoutElementsController.Address(
                country: country,
                line1: line1,
                line2: line2,
                city: city,
                state: state,
                postalCode: postalCode
            )
            return shippingDetails
        }

        var checkoutBillingDetails: CheckoutElementsController.Configuration.Defaults.BillingDetails? {
            let billingName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let billingCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !billingName.isEmpty || !billingCountry.isEmpty else {
                return nil
            }
            var billingDetails = CheckoutElementsController.Configuration.Defaults.BillingDetails()
            billingDetails.name = billingName.isEmpty ? nil : billingName
            if !billingCountry.isEmpty {
                billingDetails.address = CheckoutElementsController.Address(
                    country: billingCountry.uppercased(),
                    line1: line1.isEmpty ? nil : line1,
                    line2: line2.isEmpty ? nil : line2,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    postalCode: postalCode.isEmpty ? nil : postalCode
                )
            }
            return billingDetails
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

    /// How Payment Element is presented when it is shown. `IntegrationType.eceOnly` means Payment Element is hidden.
    enum PaymentElementPresentation: String, CaseIterable, Identifiable {
        case sheet
        case view

        var id: String { rawValue }

        var integrationType: IntegrationType {
            switch self {
            case .sheet: return .flowController
            case .view: return .embedded
            }
        }

        init?(integrationType: IntegrationType) {
            switch integrationType {
            case .flowController: self = .sheet
            case .embedded: self = .view
            case .eceOnly: return nil
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
                return "Clothing"
            case .zeroAmount:
                return "Free T-Shirt ($0)"
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
        var applePayButtonType: ApplePayButtonType
        var linkDisplay: ExpressCheckoutElement.Configuration.LinkConfiguration.Display
        var appearance: ExpressCheckoutElement.Configuration.Appearance

        init(
            isEnabled: Bool = true,
            applePayButtonType: ApplePayButtonType = .unset,
            linkDisplay: ExpressCheckoutElement.Configuration.LinkConfiguration.Display = .automatic,
            appearance: ExpressCheckoutElement.Configuration.Appearance = .init()
        ) {
            self.isEnabled = isEnabled
            self.applePayButtonType = applePayButtonType
            self.linkDisplay = linkDisplay
            self.appearance = appearance
        }

        private enum CodingKeys: String, CodingKey {
            case isEnabled
            case applePayButtonType
            case linkDisplay
            case buttonTheme
            case cornerRadius
            case maxColumns
            case maxRows
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            var appearance = ExpressCheckoutElement.Configuration.Appearance()
            appearance.buttonTheme = try container.decodeIfPresent(String.self, forKey: .buttonTheme)
                .flatMap(ExpressCheckoutElement.Configuration.Appearance.ButtonTheme.init(rawValue:)) ?? .automatic
            appearance.cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadius)
            appearance.buttonLayout.maxColumns = try container.decodeIfPresent(Int.self, forKey: .maxColumns)
            appearance.buttonLayout.maxRows = try container.decodeIfPresent(Int.self, forKey: .maxRows)

            self.init(
                isEnabled: try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true,
                applePayButtonType: try container.decodeIfPresent(ApplePayButtonType.self, forKey: .applePayButtonType) ?? .unset,
                linkDisplay: try container.decodeIfPresent(String.self, forKey: .linkDisplay)
                    .flatMap(ExpressCheckoutElement.Configuration.LinkConfiguration.Display.init(rawValue:)) ?? .automatic,
                appearance: appearance
            )
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(isEnabled, forKey: .isEnabled)
            try container.encode(applePayButtonType, forKey: .applePayButtonType)
            try container.encode(linkDisplay.rawValue, forKey: .linkDisplay)
            try container.encode(appearance.buttonTheme.rawValue, forKey: .buttonTheme)
            try container.encodeIfPresent(appearance.cornerRadius, forKey: .cornerRadius)
            try container.encodeIfPresent(appearance.buttonLayout.maxColumns, forKey: .maxColumns)
            try container.encodeIfPresent(appearance.buttonLayout.maxRows, forKey: .maxRows)
        }
    }

    struct Settings: Codable {

        var uiFramework: UIFramework = .swiftUI
        var integrationType: IntegrationType = .flowController
        var expressCheckoutElement = ExpressCheckoutElementSettings()
        var applePayEnabled = true
        var paymentElementApplePayDisplay: PaymentElementApplePayDisplay = .automatic
        var linkMode: LinkMode = .native
        var currency: Currency = .usd
        var customerType: CustomerType = .guest
        var email: EmailSettings? = .init()
        var cartScenario: CartScenario = .standard
        var shippingAddressCollection = true
        var defaultShippingAddressOption: DefaultAddressOption = .none
        var customDefaultShippingAddress = DefaultAddress.usTestAddress
        var billingAddressCollection: BillingAddressCollection = .automatic
        var defaultBillingAddressOption: DefaultAddressOption? = DefaultAddressOption.none
        var customDefaultBillingAddress: DefaultAddress? = .usTestAddress
        var defaultPhone: String?
        var automaticTax = true
        var checkoutSessionPaymentMethodSave = true
        var checkoutSessionPaymentMethodRemove = true
        var adaptivePricingCountry: AdaptivePricingCountry = .none
        var automaticPaymentMethods = true
        var paymentMethodTypes: Set<String> = ["card"]
        var currencySelectorAppearance = CurrencySelectorElement.Configuration.Appearance()
        var paymentElementAppearance: PaymentSheet.Appearance?
        var checkoutEndpointOption: EndpointOption = .hosted
        var checkoutEndpoint = EndpointOption.hosted.endpoint ?? ""
        var delayCheckoutClientRequests = false

        static let nsUserDefaultsKey = "CheckoutPlaygroundSettings"
    }
}

extension CheckoutPlayground.Settings {
    /// Checkout Playground links share the PaymentSheet playground's URL scheme and use this host.
    static let exportURLScheme = "stp-paymentsheet-playground"
    static let exportURLHost = "checkout"

    /// Appearance settings are left out of links: they would make the QR code too dense to generate or scan.
    /// The PaymentSheet playground also keeps its appearance out of its QR code.
    private static let keysExcludedFromExport = ["currencySelectorAppearance", "paymentElementAppearance"]

    /// A link that opens the Checkout Playground with these settings, except appearance. The query is the
    /// settings JSON, LZFSE-compressed and base64-encoded, like `PaymentSheetTestPlaygroundSettings.base64URL`.
    var exportURL: URL? {
        guard var object = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self)) as? [String: Any] else {
            return nil
        }
        Self.keysExcludedFromExport.forEach { object[$0] = nil }
        guard let json = try? JSONSerialization.data(withJSONObject: object),
              let compressed = try? (json as NSData).compressed(using: .lzfse) as Data else {
            return nil
        }
        return URL(string: "\(Self.exportURLScheme)://\(Self.exportURLHost)?\(compressed.base64EncodedString())")
    }

    static func isExportURL(_ url: URL) -> Bool {
        url.scheme == exportURLScheme && url.host == exportURLHost
    }

    /// Decodes settings from an `exportURL`, taking any setting the link doesn't include, such as appearance,
    /// from `base`. Returns `nil` if the link is malformed.
    init?(exportURL url: URL, base: Self) {
        guard Self.isExportURL(url),
              let query = url.query,
              let compressed = Data(base64Encoded: query),
              let json = try? (compressed as NSData).decompressed(using: .lzfse) as Data,
              let linkObject = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let baseObject = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as? [String: Any],
              let merged = try? JSONSerialization.data(withJSONObject: baseObject.merging(linkObject) { _, link in link }),
              let settings = try? JSONDecoder().decode(Self.self, from: merged) else {
            return nil
        }
        self = settings
    }
}
