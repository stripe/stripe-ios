//
//  PlaygroundMainViewModel.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import StripeFinancialConnections
import UIKit

final class PlaygroundMainViewModel: ObservableObject {

    enum Flow: String, CaseIterable, Identifiable {
        case data
        case payments
        case networking

        var id: String {
            return rawValue
        }
    }
    @Published var flow: Flow = Flow(rawValue: PlaygroundUserDefaults.flow) ?? .data {
        didSet {
            PlaygroundUserDefaults.flow = flow.rawValue
            if flow != .networking {
                email = ""
            }
        }
    }

    enum NativeSelection: String, CaseIterable, Identifiable {
        case automatic
        case web
        case native

        var id: String {
            return rawValue
        }
    }
    @Published var nativeSelection: NativeSelection {
        didSet {
            switch nativeSelection {
            case .automatic:
                PlaygroundUserDefaults.enableNative = nil
            case .web:
                PlaygroundUserDefaults.enableNative = false
            case .native:
                PlaygroundUserDefaults.enableNative = true
            }
        }
    }
    @Published var enableNative: Bool? = PlaygroundUserDefaults.enableNative {
        didSet {
            PlaygroundUserDefaults.enableNative = enableNative
        }
    }

    @Published var enableTestMode: Bool = PlaygroundUserDefaults.enableTestMode {
        didSet {
            PlaygroundUserDefaults.enableTestMode = enableTestMode
        }
    }

    @Published var email: String = PlaygroundUserDefaults.email {
        didSet {
            PlaygroundUserDefaults.email = email
        }
    }

    @Published var enableTransactionsPermission: Bool = PlaygroundUserDefaults.enableTransactionsPermission {
        didSet {
            PlaygroundUserDefaults.enableTransactionsPermission = enableTransactionsPermission
        }
    }

    @Published var enableBalancesPermission: Bool = PlaygroundUserDefaults.enableBalancesPermission {
        didSet {
            PlaygroundUserDefaults.enableBalancesPermission = enableBalancesPermission
        }
    }

    enum CustomScenario: String, CaseIterable, Identifiable {
        case none = "none"
        case customKeys = "custom_keys"
        case partnerD = "partner_d"
        case partnerF = "partner_f"
        case partnerM = "partner_m"
        case appToApp = "app_to_app"
        /// Used for random bug bashes and could changes any time
        case bugBash = "bug_bash"

        var id: String {
            return rawValue
        }

        var displayName: String {
            switch self {
            case .none:
                return "Default"
            case .customKeys:
                return "Custom Keys"
            case .partnerD:
                return "Partner D"
            case .partnerF:
                return "Partner F"
            case .partnerM:
                return "Partner M"
            case .appToApp:
                return "App to App (Chase)"
            case .bugBash:
                return "Bug Bash"
            }
        }
    }
    @Published var customScenario: CustomScenario = CustomScenario(rawValue: PlaygroundUserDefaults.customScenario) ?? .none {
        didSet {
            PlaygroundUserDefaults.customScenario = customScenario.rawValue
        }
    }
    @Published var customPublicKey: String = PlaygroundUserDefaults.customPublicKey {
        didSet {
            PlaygroundUserDefaults.customPublicKey = customPublicKey
        }
    }
    @Published var customSecretKey: String = PlaygroundUserDefaults.customSecretKey {
        didSet {
            PlaygroundUserDefaults.customSecretKey = customSecretKey
        }
    }

    @Published var isLoading: Bool = false

    init() {
        self.nativeSelection = {
            if let enableNative = PlaygroundUserDefaults.enableNative {
                return enableNative ? .native : .web
            } else {
                return .automatic
            }
        }()
    }

    func didSelectShow() {
        setup()
    }

    private func setup() {
        isLoading = true
        SetupPlayground(
            enableTestMode: enableTestMode,
            flow: flow.rawValue,
            email: email,
            enableTransactionsPermission: enableTransactionsPermission,
            enableBalancesPermission: enableBalancesPermission,
            customScenario: customScenario.rawValue,
            customPublicKey: customPublicKey,
            customSecretKey: customSecretKey
        ) { [weak self] setupPlaygroundResponse in
            if let setupPlaygroundResponse = setupPlaygroundResponse {
                PresentFinancialConnectionsSheet(
                    setupPlaygroundResponseJSON: setupPlaygroundResponse
                ) { result in
                    switch result {
                    case .completed(let session):
                        let accounts = session.accounts.data.filter { $0.last4 != nil }
                        let accountInfos = accounts.map { "\($0.institutionName) ....\($0.last4!)" }
                        let sessionInfo =
"""
session_id=\(session.id)
account_names=\(session.accounts.data.map({ $0.displayName ?? "N/A" }))
account_ids=\(session.accounts.data.map({ $0.id }))
"""

                        UIAlertController.showAlert(
                            title: "Success",
                            message: "\(accountInfos)\n\n\(sessionInfo)"
                        )
                    case .canceled:
                        UIAlertController.showAlert(
                            title: "Cancelled"
                        )
                    case .failed(let error):
                        UIAlertController.showAlert(
                            title: "Failed",
                            message: {
                                if case .unknown(let debugDescription) = error as? FinancialConnectionsSheetError {
                                    return debugDescription
                                } else {
                                    return error.localizedDescription
                                }
                            }()
                        )
                    }
                }
            } else {
                UIAlertController.showAlert(
                    title: "Playground App Setup Failed",
                    message: "Try clearing 'Custom Keys' or delete & re-install the app."
                )
            }
            self?.isLoading = false
        }
    }

    func didSelectClearCaches() {
        URLSession.shared.reset(completionHandler: {})
    }
}

private func SetupPlayground(
    enableTestMode: Bool,
    flow: String,
    email: String,
    enableTransactionsPermission: Bool,
    enableBalancesPermission: Bool,
    customScenario: String,
    customPublicKey: String,
    customSecretKey: String,
    completionHandler: @escaping ([String: String]?) -> Void
) {
    if !enableTestMode && email == "test@test.com" {
        assertionFailure("\(email) will not work with livemode, it will return rate limit exceeded")
    }

    let baseURL = "https://financial-connections-playground-ios.glitch.me"
    let endpoint = "/setup_playground"
    let url = URL(string: baseURL + endpoint)!

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
        var requestBody: [String: Any] = [:]
        requestBody["enable_test_mode"] = enableTestMode
        requestBody["flow"] = flow
        requestBody["email"] = email
        requestBody["enable_transactions_permission"] = enableTransactionsPermission
        requestBody["enable_balances_permission"] = enableBalancesPermission
        requestBody["custom_scenario"] = customScenario
        requestBody["custom_public_key"] = customPublicKey
        requestBody["custom_secret_key"] = customSecretKey
        return try! JSONSerialization.data(
            withJSONObject: requestBody,
            options: .prettyPrinted
        )
    }()
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared
        .dataTask(
            with: urlRequest
        ) { data, response, error in
            if error == nil,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
            {
                DispatchQueue.main.async {
                    completionHandler(responseJson)
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            }
        }
        .resume()
}

private func PresentFinancialConnectionsSheet(
    setupPlaygroundResponseJSON: [String: String],
    completionHandler: @escaping (FinancialConnectionsSheet.Result) -> Void
) {
    guard let clientSecret = setupPlaygroundResponseJSON["client_secret"] else {
        completionHandler(
            .failed(
                error: FinancialConnectionsSheetError
                    .unknown(
                        debugDescription: "Server returned no client_secret. Try clearing 'Custom Keys' or delete & re-install the app."
                    )
            )
        )
        return
    }
    guard let publishableKey = setupPlaygroundResponseJSON["publishable_key"] else {
        completionHandler(
            .failed(
                error: FinancialConnectionsSheetError
                    .unknown(
                        debugDescription: "Server returned no publishable_key. Try clearing 'Custom Keys' or delete & re-install the app."
                    )
            )
        )
        return
    }

    STPAPIClient.shared.publishableKey = publishableKey

    let financialConnectionsSheet = FinancialConnectionsSheet(
        financialConnectionsSessionClientSecret: clientSecret,
        returnURL: "financial-connections-example://redirect"
    )
    financialConnectionsSheet.onEvent = { event in
        print("Received event: \(event.name.rawValue), \(event.metadata.dictionary)")
        //       Log.d("EVENT", "Received event: ${event.name}, ${event.metadata.toMap()}")
//        FinancialConnectionsEvent.ErrorCode.failedBotDetection
        switch event.name {
        case .manualEntryInitiated:
            break
        default:
            break
        }
    }
    financialConnectionsSheet.present(
        from: UIViewController.topMostViewController()!,
        completion: { result in
            completionHandler(result)
            _ = financialConnectionsSheet  // retain the sheet
        }
    )
}
