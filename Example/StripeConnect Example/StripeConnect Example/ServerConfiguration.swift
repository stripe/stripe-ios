//
//  ServerConfiguration.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/3/24.
//

import StripeConnect

/// Configures the server and saves to UserDefaults.
/// This comes with a few pre-configured demo accounts and demo server.
enum ServerConfiguration {

    /// Keys used to store/retrieve user defaults
    enum DefaultsKeys: String {
        case account
        case publishableKey
        case endpoint
    }

    /// Some pre-configured demo accounts
    enum DemoAccounts: String, CaseIterable {
        static var `default`: Self { .standardCBSP }

        case standardCBSP = "acct_1NBR5cQ55yzNh0Wh"
        case standardNonCBSP = "acct_1NTYufAm9SMRj986"
        case express = "acct_1MhgrJPu4nAj1Tce"
        case custom = "acct_1N9FIXQ26HdRlxHg"
        case ua1 = "acct_1NUwRpPwYwgmBZjm"
        case ua2 = "acct_1N61ByQ7NMZInEnp"
        case ua3 = "acct_1NUwSMPxxtPxBTFe"
        case ua4 = "acct_1P0rIJPrS3d8qFkO"
        case pns = "acct_1NUwSoPqPnXR0qy5"
        case sns = "acct_1OxEPrQ4YLD3lwUp"
    }

    case demo(DemoAccounts)
    case customAccount(String)
    case customEndpoint(_ endpoint: URL, publishableKey: String)
}

extension ServerConfiguration {
    private static let defaults = UserDefaults.standard

    static let platformAccount = "acct_1MZRIlLirQdaQn8E"

    static var shared: ServerConfiguration = {
        if let account = defaults.string(forKey: DefaultsKeys.account.rawValue) {
            return DemoAccounts(rawValue: account).map(ServerConfiguration.demo) ?? .customAccount(account)
        }

        guard let endpointString = defaults.string(forKey: DefaultsKeys.endpoint.rawValue),
              let endpoint = URL(string: endpointString),
              let publishableKey = defaults.string(forKey: DefaultsKeys.publishableKey.rawValue) else {
            return .demo(.default)
        }

        return .customEndpoint(endpoint, publishableKey: publishableKey)
    }() {
        didSet {
            switch shared {
            case .demo(let account):
                defaults.set(account.rawValue, forKey: DefaultsKeys.account.rawValue)
                defaults.removeObject(forKey: DefaultsKeys.endpoint.rawValue)
                defaults.removeObject(forKey: DefaultsKeys.publishableKey.rawValue)
            case .customAccount(let account):
                defaults.set(account, forKey: DefaultsKeys.account.rawValue)
                defaults.removeObject(forKey: DefaultsKeys.endpoint.rawValue)
                defaults.removeObject(forKey: DefaultsKeys.publishableKey.rawValue)
            case .customEndpoint(let endpoint, let publishableKey):
                defaults.removeObject(forKey: DefaultsKeys.account.rawValue)
                defaults.set(endpoint.absoluteString, forKey: DefaultsKeys.endpoint.rawValue)
                defaults.set(publishableKey, forKey: DefaultsKeys.publishableKey.rawValue)
            }

            defaults.synchronize()

            // Update publishable key
            STPAPIClient.shared.publishableKey = shared.publishableKey
        }
    }

    var account: String? {
        switch self {
        case .demo(let account):
            return account.rawValue
        case .customAccount(let account):
            return account
        case .customEndpoint:
            return nil
        }
    }

    var endpoint: URL {
        switch self {
        case .demo, .customAccount:
            return URL(string: "https://stripe-connect-example.glitch.me/account_session")!
        case .customEndpoint(let endpoint, _):
            return endpoint
        }
    }

    var publishableKey: String {
        switch self {
        case .demo, .customAccount:
            return "pk_test_51MZRIlLirQdaQn8EJpw9mcVeXokTGaiV1ylz5AVQtcA0zAkoM9fLFN81yQeHYBLkCiID1Bj0sL1Ngzsq9ksRmbBN00O3VsIUdQ"
        case .customEndpoint(_, let publishableKey):
            return publishableKey
        }
    }
}

extension ServerConfiguration.DemoAccounts {
    /// Display label
    var label: String {
        switch self {
        case .standardCBSP:
            return "Standard CBSP (SSS)"
        case .standardNonCBSP:
            return "Standard Non-CBSP"
        case .express:
            return "Express"
        case .custom:
            return "Custom"
        case .ua1:
            return "UA1 (PSP)"
        case .ua2:
            return "UA2 (PSS)"
        case .ua3:
            return "UA3 (PNP)"
        case .ua4:
            return "UA4 (PEP)"
        case .pns:
            return "PNS (UA7 with platform owns pricing)"
        case .sns:
            return "SNS (UA7 with Stripe owns pricing)"
        }
    }
}

extension ServerConfiguration {
    var label: String {
        switch self {
        case .demo(let account):
            return account.label
        case .customAccount(let account):
            return account
        case .customEndpoint(let endpoint, _):
            return endpoint.host ?? "Custom endpoint"
        }
    }
}
