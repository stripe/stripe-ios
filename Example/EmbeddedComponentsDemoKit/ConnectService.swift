//
//  ConnectService.swift
//  EmbeddedComponentsDemoKit
//

import Foundation
import Observation
@_spi(DashboardOnly) import StripeConnect
import UIKit

/// Talks to a locally running copy of the StripeConnect example backend, configured to enable every
/// component these demos use.
enum DemoBackend {
    static let baseURL = URL(string: "http://localhost:8081")!

    struct AppInfo: Decodable {
        let publishableKey: String
        let availableMerchants: [Merchant]
    }

    struct Merchant: Decodable, Identifiable, Hashable {
        let displayName: String?
        let merchantId: String
        var id: String { merchantId }
    }

    private struct AccountSession: Decodable {
        let clientSecret: String
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static func appInfo() async throws -> AppInfo {
        let (data, _) = try await URLSession.shared.data(from: baseURL.appendingPathComponent("app_info"))
        return try decoder.decode(AppInfo.self, from: data)
    }

    static func clientSecret(for merchantId: String) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("account_session"))
        request.httpMethod = "POST"
        request.setValue(merchantId, forHTTPHeaderField: "account")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(AccountSession.self, from: data).clientSecret
    }
}

/// What an embedded component sits on, so its background can match exactly.
enum EmbeddedComponentSurface {
    /// Inside a raised card.
    case card
    /// Directly on the page, with no card around it.
    case page
}

@MainActor
@Observable
final class ConnectService {
    private(set) var merchants: [DemoBackend.Merchant] = []
    private(set) var isReady = false
    private(set) var loadError: String?
    /// Account used for onboarding (adding a payout destination for the first time).
    var onboardingMerchantId = "acct_1SxE0tLRuQcyS3ni" // Onboarding (Custom W)
    /// Account used for withdrawals and payout-method management: a funded recipient account with
    /// Stripe user authentication disabled so payout destinations can be edited inline.
    var payoutsMerchantId = "acct_1UL7B5LXJrbzE6ZX" // Kestrel demo (Alex Rivera)

    private let appearance: (EmbeddedComponentSurface) -> EmbeddedComponentManager.Appearance

    /// - Parameter appearance: The app's theme for embedded components on each surface.
    init(appearance: @escaping (EmbeddedComponentSurface) -> EmbeddedComponentManager.Appearance) {
        self.appearance = appearance
    }

    func prepare() async {
        guard !isReady else { return }
        do {
            let info = try await DemoBackend.appInfo()
            STPAPIClient.shared.publishableKey = info.publishableKey
            merchants = info.availableMerchants
            isReady = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    func makeComponentManager(
        for merchantId: String,
        surface: EmbeddedComponentSurface = .card
    ) -> EmbeddedComponentManager {
        EmbeddedComponentManager(
            appearance: appearance(surface),
            fetchClientSecret: {
                try? await DemoBackend.clientSecret(for: merchantId)
            }
        )
    }
}

extension EmbeddedComponentManager.Appearance.Typography.Style {
    static func style(_ size: CGFloat, _ weight: UIFont.Weight) -> Self {
        var style = Self()
        style.fontSize = size
        style.weight = weight
        return style
    }
}
