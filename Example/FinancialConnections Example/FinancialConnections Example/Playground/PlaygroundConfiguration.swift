//
//  PlaygroundConfiguration.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/4/24.
//

import Foundation

private final class PlaygroundConfigurationJSON {

    private static var configurationJSONStringDefaultValue = "{}"

    @UserDefault(
        key: "FINANCIAL_CONNECTIONS_EXAMPLE_CONFIGURATION_JSON_STRING",
        defaultValue: configurationJSONStringDefaultValue
    )
    private static var configurationJSONString: String

    fileprivate var dictionary: [String: Any] {
        get {
            print("^ dictionary:get:", Self.configurationJSONString)
            let configurationJSONString = Self.configurationJSONString
            if configurationJSONString.isEmpty {
                return [:]
            } else {
                if let jsonData = configurationJSONString.data(using: .utf8) {
                    do {
                        if let dictionary = (try JSONSerialization.jsonObject(with: jsonData, options: [])) as? [String: Any] {
                            return dictionary
                        } else {
                            Self.configurationJSONString = Self.configurationJSONStringDefaultValue
                            assertionFailure("unable to convert `configurationJSONString` to a dictionary `[String:Any]`")
                            return [:]
                        }
                    } catch {
                        Self.configurationJSONString = Self.configurationJSONStringDefaultValue
                        assertionFailure("encountered an error when using `JSONSerialization.jsonObject`: \(error.localizedDescription)")
                        return [:]
                    }
                } else {
                    Self.configurationJSONString = Self.configurationJSONStringDefaultValue
                    assertionFailure("unable to convert `configurationJSONString` to data using `configurationJSONString.data(using: .utf8)`")
                    return [:]
                }
            }
        }
        set {
            do {
                let configurationJSONData = try JSONSerialization.data(withJSONObject: newValue, options: [])
                if let configurationJSONString = String(data: configurationJSONData, encoding: .utf8) {
                    Self.configurationJSONString = configurationJSONString
                } else {
                    assertionFailure("unable to convert `configurationJSONData` to a `configurationJSONString`")
                }
            } catch {
                assertionFailure("encountered an error when using `JSONSerialization.jsonObject`: \(error.localizedDescription)")
            }
            print("^ dictionary:set:", Self.configurationJSONString)
        }
    }

    subscript(key: String) -> Any? {
        get {
            return dictionary[key]
        }
        set(newValue) {
            dictionary[key] = newValue
        }
    }

    var string: String {
        return Self.configurationJSONString
    }

    var isEmpty: Bool {
        return dictionary.isEmpty
    }
}

// we want the JSON to represent the source of truth
// - initially it will be NULL...so something needs to set it up

final class PlaygroundConfiguration {

    // Singleton

    static let shared = PlaygroundConfiguration()

    // Rest

    private let configurationJSON = PlaygroundConfigurationJSON()
    var configurationJSONString: String {
        return configurationJSON.string
    }
    var configurationJSONDictionary: [String: Any] {
        return configurationJSON.dictionary
    }

    private init() {
        // setup defaults if this is the first time initializing
        setupWithConfigurationJSONString(configurationJSONString)
    }

    // MARK: - SDK Type

    enum SDKType: String, CaseIterable, Identifiable, Hashable {
        case automatic = "automatic"
        case web = "web"
        case native = "native"

        var id: String {
            return rawValue
        }
    }
    private static let sdkTypeKey = "sdk_type"
    var sdkType: SDKType {
        get {
            if
                let sdkTypeString = configurationJSON[Self.sdkTypeKey] as? String,
                let sdkType = SDKType(rawValue: sdkTypeString)
            {
                return sdkType
            } else {
                return .native
            }
        }
        set {
            configurationJSON[Self.sdkTypeKey] = newValue.rawValue
        }
    }

    // MARK: - Merchant

    struct Merchant: Identifiable, Equatable, Hashable {
        /// what we pass to the backend and store in the configuration JSON
        let customId: String
        /// what the playground app displays
        let displayName: String
        /// whether on the 'backend' we provide test mode keys
        let isTestModeSupported: Bool

        var id: String {
            return customId
        }
    }

    let merchants: [Merchant] = [
        Merchant(
            customId: "default",
            displayName: "Default (non-networking)",
            isTestModeSupported: true
        ),
        Merchant(
            customId: "networking",
            displayName: "Networking",
            isTestModeSupported: true
        ),
        Merchant(
            customId: "custom-keys",
            displayName: "Custom Keys",
            isTestModeSupported: false
        ),
    ]
    private static let merchantCustomIdKey = "merchant"
    var merchant: Merchant {
        get {
            if
                let merchantCustomId = configurationJSON[Self.merchantCustomIdKey] as? String,
                let merchant = merchants.first(where: { $0.customId == merchantCustomId })
            {
                return merchant
            } else {
                return merchants.first!
            }
        }
        set {
            configurationJSON[Self.merchantCustomIdKey] = newValue.customId
        }
    }

    // MARK: - Test Mode

    private static let testModeKey = "test_mode"
    var testMode: Bool {
        get {
            if let testMode = configurationJSON[Self.testModeKey] as? Bool {
                return testMode
            } else {
                return false
            }
        }
        set {
            configurationJSON[Self.testModeKey] = newValue
        }
    }

    // MARK: - Custom Keys

    private static let customPublicKeyKey = "custom_public_key"
    var customPublicKey: String {
        get {
            if let customPublicKey = configurationJSON[Self.customPublicKeyKey] as? String {
                return customPublicKey
            } else {
                return ""
            }
        }
        set {
            configurationJSON[Self.customPublicKeyKey] = newValue
        }
    }
    private static let customSecretKeyKey = "custom_secret_key"
    var customSecretKey: String {
        get {
            if let customSecretKey = configurationJSON[Self.customSecretKeyKey] as? String {
                return customSecretKey
            } else {
                return ""
            }
        }
        set {
            configurationJSON[Self.customSecretKeyKey] = newValue
        }
    }

    // MARK: - Use Case

    enum UseCase: String, CaseIterable, Identifiable, Hashable {
        case data = "data"
        case paymentIntent = "payment_intent"

        var id: String {
            return rawValue
        }
    }
    private static let useCaseKey = "use_case"
    var useCase: UseCase {
        get {
            if
                let useCaseString = configurationJSON[Self.useCaseKey] as? String,
                let useCase = UseCase(rawValue: useCaseString)
            {
                return useCase
            } else {
                return .data
            }
        }
        set {
            configurationJSON[Self.useCaseKey] = newValue.rawValue
        }
    }

    // MARK: - Customer

    private static let emailKey = "email"
    var email: String {
        get {
            if let email = configurationJSON[Self.emailKey] as? String {
                return email
            } else {
                return ""
            }
        }
        set {
            configurationJSON[Self.emailKey] = newValue
        }
    }

    // MARK: - Other

    func setupWithConfigurationJSONString(_ configurationJSONString: String) {
        guard
            let jsonData = configurationJSONString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let dictionary = jsonObject as? [String: Any]
        else {
            return
        }

        if
            let sdkTypeString = dictionary[Self.sdkTypeKey] as? String,
            let sdkType = SDKType(rawValue: sdkTypeString)
        {
            self.sdkType = sdkType
        } else {
            self.sdkType = .native
        }

        if
            let merchantCustomId = dictionary[Self.merchantCustomIdKey] as? String,
            let merchant = merchants.first(where: { $0.id == merchantCustomId })
        {
            self.merchant = merchant
        } else {
            self.merchant = merchants.first!
        }

        if let testMode = dictionary[Self.testModeKey] as? Bool {
            self.testMode = testMode
        } else {
            self.testMode = false
        }

        if
            let customPublicKey = dictionary[Self.customPublicKeyKey] as? String,
            let customSecretKey = dictionary[Self.customSecretKeyKey] as? String,
            !customPublicKey.isEmpty,
            !customSecretKey.isEmpty
        {
            self.customPublicKey = customPublicKey
            self.customSecretKey = customSecretKey
        } else {
            self.customPublicKey = ""
            self.customSecretKey = ""
        }

        if
            let useCaseString = dictionary[Self.useCaseKey] as? String,
            let useCase = UseCase(rawValue: useCaseString)
        {
            self.useCase = useCase
        } else {
            self.useCase = .data
        }

        if
            let email = dictionary[Self.emailKey] as? String
        {
            self.email = email
        } else {
            self.email = ""
        }
    }
}
