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
    var configurationString: String {
        return configurationStore.configurationString
    }
    var configurationDictionary: [String: Any] {
        return configurationStore.configurationDictionary
    }

    private init() {
        // setup defaults if this is the first time initializing
        updateConfigurationString(configurationString)

        // load configuration for UI tests if present
        if let configurationString = ProcessInfo.processInfo.environment["UITesting_playground_configuration_string"] {
            updateConfigurationString(configurationString)
        }
    }

    // MARK: - Experience

    enum Experience: String, CaseIterable, Identifiable, Hashable {
        case financialConnections = "financial_connections"
        case instantDebits = "instant_debits"

        var displayName: String {
            switch self {
            case .financialConnections: "Financial Connections"
            case .instantDebits: "Instant Debits"
            }
        }

        var id: String {
            return rawValue
        }
    }

    private static let experienceKey = "experience"

    var experience: Experience {
        get {
            if
                let sdkTypeString = configurationStore[Self.experienceKey] as? String,
                let sdkType = Experience(rawValue: sdkTypeString)
            {
                return sdkType
            } else {
                return .financialConnections
            }
        }
        set {
            configurationStore[Self.experienceKey] = newValue.rawValue
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
        let customId: CustomId
        /// what the playground app displays
        let displayName: String
        /// whether on the 'backend' we provide test mode keys
        let isTestModeSupported: Bool
        /// for connect
        let stripeAccount: String?

        var id: String {
            return customId.rawValue
        }

        init(
            customId: CustomId,
            displayName: String,
            isTestModeSupported: Bool,
            stripeAccount: String? = nil
        ) {
            self.customId = customId
            self.displayName = displayName
            self.isTestModeSupported = isTestModeSupported
            self.stripeAccount = stripeAccount
        }

        // The id's should use underscore as "-" is not supported in Glitch
        enum CustomId: String {
            case `default` = "default"
            case networking = "networking"
            case connect = "connect"
            case customKeys = "custom_keys"
            case partnerD = "partner_d"
            case partnerF = "partner_f"
            case platformC = "platform_c"
            case bugBash = "bug_bash"
        }
    }

    let merchants: [Merchant] = [
        Merchant(
            customId: .default,
            displayName: "Default (non-networking)",
            isTestModeSupported: true
        ),
        Merchant(
            customId: .networking,
            displayName: "Networking",
            isTestModeSupported: true
        ),
        Merchant(
            customId: .connect,
            displayName: "Connect",
            isTestModeSupported: true,
            stripeAccount: "acct_1PnnD9CY58qxxwvr"
        ),
        Merchant(
            customId: .customKeys,
            displayName: "Custom Keys",
            isTestModeSupported: false
        ),
        Merchant(
            customId: .partnerD,
            displayName: "Partner D",
            isTestModeSupported: false
        ),
        Merchant(
            customId: .partnerF,
            displayName: "Partner F",
            isTestModeSupported: false
        ),
        Merchant(
            customId: .platformC,
            displayName: "Platform C",
            isTestModeSupported: true
        ),
        Merchant(
            customId: .bugBash,
            displayName: "Bug Bash",
            isTestModeSupported: true
        ),

    ]
    private static let merchantCustomIdKey = "merchant"
    private static let stripeAccountKey = "stripe_account"
    var merchant: Merchant {
        get {
            if
                let merchantCustomId = configurationStore[Self.merchantCustomIdKey] as? String,
                let merchant = merchants.first(where: { $0.customId.rawValue == merchantCustomId })
            {
                // make sure test mode is off for merchants where test mode is turned off
                if !merchant.isTestModeSupported, testMode {
                    testMode = false
                }
                return merchant
            } else {
                return merchants.first!
            }
        }
        set {
            // make sure test mode is off for merchants where test mode is turned off
            if !merchant.isTestModeSupported, testMode {
                testMode = false
            }
            configurationStore[Self.merchantCustomIdKey] = newValue.customId.rawValue
            configurationStore[Self.stripeAccountKey] = newValue.stripeAccount
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
        case token = "token"

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

    private static let phoneKey = "phone"
    var phone: String {
        get {
            if let phone = configurationStore[Self.phoneKey] as? String {
                return phone
            } else {
                return ""
            }
        }
        set {
            configurationStore[Self.phoneKey] = newValue
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

    // MARK: - Other Settings

    private static let liveEventsKey = "live_events"
    var liveEvents: Bool {
        get {
            if let liveEvents = configurationStore[Self.liveEventsKey] as? Bool {
                return liveEvents
            } else {
                return false
            }
        }
        set {
            configurationStore[Self.liveEventsKey] = newValue
        }
    }

    // MARK: - Update

    func updateConfigurationString(_ configurationString: String) {
        guard
            let jsonData = configurationString.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
            let dictionary = jsonObject as? [String: Any]
        else {
            // this prevents anyone from overriding the configuration with something wrong
            assertionFailure("failed to update configuration string")
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
            let experienceString = dictionary[Self.experienceKey] as? String,
            let experience = Experience(rawValue: experienceString)
        {
            self.experience = experience
        } else {
            self.experience = .financialConnections
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

        if let phone = dictionary[Self.phoneKey] as? String {
            self.phone = phone
        } else {
            self.phone = ""
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

        if let liveEvents = dictionary[Self.liveEventsKey] as? Bool {
            self.liveEvents = liveEvents
        } else {
            self.liveEvents = false
        }
    }
}

/// A simple wrapper around playground configuration NSUserDefaults JSON string.
final class PlaygroundConfigurationStore {

    static let configurationStringDefaultValue = "{}"

    @UserDefault(
        key: "FINANCIAL_CONNECTIONS_EXAMPLE_CONFIGURATION_STRING",
        defaultValue: configurationStringDefaultValue
    )
    private static var configurationString: String

    fileprivate var configurationDictionary: [String: Any] {
        get {
            let configurationString = Self.configurationString
            if configurationString.isEmpty {
                return [:]
            } else {
                if let configurationData = configurationString.data(using: .utf8) {
                    do {
                        if let dictionary = (try JSONSerialization.jsonObject(with: configurationData, options: [])) as? [String: Any] {
                            return dictionary
                        } else {
                            Self.configurationString = Self.configurationStringDefaultValue
                            assertionFailure("unable to convert `configurationString` to a dictionary `[String:Any]`")
                            return [:]
                        }
                    } catch {
                        Self.configurationString = Self.configurationStringDefaultValue
                        assertionFailure("encountered an error when using `JSONSerialization.jsonObject`: \(error.localizedDescription)")
                        return [:]
                    }
                } else {
                    Self.configurationString = Self.configurationStringDefaultValue
                    assertionFailure("unable to convert `configurationString` to data using `configurationString.data(using: .utf8)`")
                    return [:]
                }
            }
        }
        set {
            do {
                let configurationData = try JSONSerialization.data(withJSONObject: newValue, options: [])
                if let configurationString = String(data: configurationData, encoding: .utf8) {
                    Self.configurationString = configurationString
                } else {
                    assertionFailure("unable to convert `configurationData` to a `configurationString`")
                }
            } catch {
                assertionFailure("encountered an error when using `JSONSerialization.jsonObject`: \(error.localizedDescription)")
            }
        }
    }

    fileprivate subscript(key: String) -> Any? {
        get {
            return configurationDictionary[key]
        }
        set(newValue) {
            configurationDictionary[key] = newValue
        }
    }

    var configurationString: String {
        return Self.configurationString
    }

    var isEmpty: Bool {
        return configurationDictionary.isEmpty
    }
}
