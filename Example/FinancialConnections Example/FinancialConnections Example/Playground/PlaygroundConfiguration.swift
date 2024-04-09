//
//  PlaygroundConfiguration.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/4/24.
//

import Foundation

/// Provides an interface to customize the playground configuration
/// (which is stored as a JSON in NSUserDefaults).
final class PlaygroundConfiguration {

    static let shared = PlaygroundConfiguration()

    private let configurationStore = PlaygroundConfigurationStore()
    var configurationJSONString: String {
        return configurationStore.configurationJSONString
    }
    var configurationJSONDictionary: [String: Any] {
        return configurationStore.configurationJSONDictionary
    }

    private init() {
        // setup defaults if this is the first time initializing
        updateConfigurationJSONString(configurationJSONString)

        // load configuration for UI tests if present
        if let configurationJSONString = ProcessInfo.processInfo.environment["UITesting_configuration_json_string"] {
            updateConfigurationJSONString(configurationJSONString)
        }
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
                let sdkTypeString = configurationStore[Self.sdkTypeKey] as? String,
                let sdkType = SDKType(rawValue: sdkTypeString)
            {
                return sdkType
            } else {
                return .native
            }
        }
        set {
            configurationStore[Self.sdkTypeKey] = newValue.rawValue

            switch newValue {
            case .automatic:
                PlaygroundUserDefaults.enableNative = nil
            case .web:
                PlaygroundUserDefaults.enableNative = false
            case .native:
                PlaygroundUserDefaults.enableNative = true
            }
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
                let merchantCustomId = configurationStore[Self.merchantCustomIdKey] as? String,
                let merchant = merchants.first(where: { $0.customId == merchantCustomId })
            {
                return merchant
            } else {
                return merchants.first!
            }
        }
        set {
            configurationStore[Self.merchantCustomIdKey] = newValue.customId
        }
    }

    // MARK: - Test Mode

    private static let testModeKey = "test_mode"
    var testMode: Bool {
        get {
            if let testMode = configurationStore[Self.testModeKey] as? Bool {
                return testMode
            } else {
                return false
            }
        }
        set {
            configurationStore[Self.testModeKey] = newValue
        }
    }

    // MARK: - Custom Keys

    private static let customPublicKeyKey = "custom_public_key"
    var customPublicKey: String {
        get {
            if let customPublicKey = configurationStore[Self.customPublicKeyKey] as? String {
                return customPublicKey
            } else {
                return ""
            }
        }
        set {
            configurationStore[Self.customPublicKeyKey] = newValue
        }
    }
    private static let customSecretKeyKey = "custom_secret_key"
    var customSecretKey: String {
        get {
            if let customSecretKey = configurationStore[Self.customSecretKeyKey] as? String {
                return customSecretKey
            } else {
                return ""
            }
        }
        set {
            configurationStore[Self.customSecretKeyKey] = newValue
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
                let useCaseString = configurationStore[Self.useCaseKey] as? String,
                let useCase = UseCase(rawValue: useCaseString)
            {
                return useCase
            } else {
                return .data
            }
        }
        set {
            configurationStore[Self.useCaseKey] = newValue.rawValue
        }
    }

    // MARK: - Customer

    private static let emailKey = "email"
    var email: String {
        get {
            if let email = configurationStore[Self.emailKey] as? String {
                return email
            } else {
                return ""
            }
        }
        set {
            configurationStore[Self.emailKey] = newValue
        }
    }

    // MARK: - Permissions

    private static let balancesPermissionKey = "balances_permission"
    var balancesPermission: Bool {
        get {
            if let balancesPermission = configurationStore[Self.balancesPermissionKey] as? Bool {
                return balancesPermission
            } else {
                return false
            }
        }
        set {
            configurationStore[Self.balancesPermissionKey] = newValue
        }
    }
    private static let ownershipPermissionKey = "ownership_permission"
    var ownershipPermission: Bool {
        get {
            if let ownershipPermission = configurationStore[Self.ownershipPermissionKey] as? Bool {
                return ownershipPermission
            } else {
                return false
            }
        }
        set {
            configurationStore[Self.ownershipPermissionKey] = newValue
        }
    }
    private static let paymentMethodPermissionKey = "payment_method_permission"
    var paymentMethodPermission: Bool {
        get {
            if let paymentMethodPermission = configurationStore[Self.paymentMethodPermissionKey] as? Bool {
                return paymentMethodPermission
            } else {
                return false
            }
        }
        set {
            configurationStore[Self.paymentMethodPermissionKey] = newValue
        }
    }
    private static let transactionsPermissionKey = "transactions_permission"
    var transactionsPermission: Bool {
        get {
            if let transactionsPermission = configurationStore[Self.transactionsPermissionKey] as? Bool {
                return transactionsPermission
            } else {
                return false
            }
        }
        set {
            configurationStore[Self.transactionsPermissionKey] = newValue
        }
    }

    // MARK: - Other

    func updateConfigurationJSONString(_ configurationJSONString: String) {
        guard
            let jsonData = configurationJSONString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let dictionary = jsonObject as? [String: Any]
        else {
            // this prevents anyone from overriding the configuration with something wrong
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

        if let email = dictionary[Self.emailKey] as? String {
            self.email = email
        } else {
            self.email = ""
        }

        if let balancesPermission = dictionary[Self.balancesPermissionKey] as? Bool {
            self.balancesPermission = balancesPermission
        } else {
            self.balancesPermission = false
        }
        if let ownershipPermission = dictionary[Self.ownershipPermissionKey] as? Bool {
            self.ownershipPermission = ownershipPermission
        } else {
            self.ownershipPermission = false
        }
        if let paymentMethodPermission = dictionary[Self.paymentMethodPermissionKey] as? Bool {
            self.paymentMethodPermission = paymentMethodPermission
        } else {
            self.paymentMethodPermission = true
        }
        if let transactionsPermission = dictionary[Self.transactionsPermissionKey] as? Bool {
            self.transactionsPermission = transactionsPermission
        } else {
            self.transactionsPermission = false
        }
    }
}

/// A simple wrapper around playground configuration NSUserDefaults JSON string.
final class PlaygroundConfigurationStore {

    static let configurationJSONStringDefaultValue = "{}"

    @UserDefault(
        key: "FINANCIAL_CONNECTIONS_EXAMPLE_CONFIGURATION_JSON_STRING",
        defaultValue: configurationJSONStringDefaultValue
    )
    private static var configurationJSONString: String

    fileprivate var configurationJSONDictionary: [String: Any] {
        get {
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
        }
    }

    fileprivate subscript(key: String) -> Any? {
        get {
            return configurationJSONDictionary[key]
        }
        set(newValue) {
            configurationJSONDictionary[key] = newValue
        }
    }

    var configurationJSONString: String {
        return Self.configurationJSONString
    }

    var isEmpty: Bool {
        return configurationJSONDictionary.isEmpty
    }
}
