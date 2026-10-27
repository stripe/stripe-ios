//
//  LinkControllerDemoConfiguration.swift
//  PaymentSheet Example
//

@_spi(LinkControllerPreview) import StripePaymentSheet
import UIKit

struct LinkControllerDemoConfiguration {
    var email: String = "foo@bar.com"
    var phone: String = ""
    var supportedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    var paymentMethodTypesMode: PaymentMethodTypesMode = .automatic
    var intentMode: IntentMode = .sdkManaged
    var useCustomAppearance: Bool = false
    var requestedFCPermissions: Set<FCPermission> = []

    enum FCPermission: String, CaseIterable {
        case paymentMethod = "payment_method"
        case balances = "balances"
        case ownership = "ownership"
        case transactions = "transactions"

        var displayName: String {
            switch self {
            case .paymentMethod: return "payment_method"
            case .balances: return "balances"
            case .ownership: return "ownership"
            case .transactions: return "transactions"
            }
        }
    }

    var financialConnectionsPermissions: [String]? {
        guard !requestedFCPermissions.isEmpty else { return nil }
        return requestedFCPermissions.map(\.rawValue).sorted()
    }

    var appearance: LinkAppearance? {
        guard useCustomAppearance else { return nil }
        let purple = UIColor(red: 0.36, green: 0.20, blue: 0.80, alpha: 1)
        return LinkAppearance(
            colors: .init(primary: purple, contentOnPrimary: .white, selectedBorder: purple),
            primaryButton: .init(cornerRadius: 6),
            style: .alwaysDark
        )
    }

    var paymentMethodTypes: [String]? {
        switch paymentMethodTypesMode {
        case .automatic:
            return nil
        case .link:
            return ["link"]
        }
    }

    enum PaymentMethodTypesMode: String, CaseIterable {
        case automatic = "Automatic"
        case link = "Link"
    }

    enum IntentMode: String, CaseIterable {
        case sdkManaged = "SDK Managed"
        case serverSetupIntent = "Server SetupIntent"
    }
}
