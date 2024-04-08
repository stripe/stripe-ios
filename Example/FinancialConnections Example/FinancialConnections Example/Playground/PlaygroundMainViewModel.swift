//
//  PlaygroundMainViewModel.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Combine
import Foundation
import StripeFinancialConnections
import SwiftUI
import UIKit

final class PlaygroundMainViewModel: ObservableObject {

    let playgroundConfiguration = PlaygroundConfiguration.shared

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
//            if flow != .networking {
//                email = ""
//            }
        }
    }

    var sdkType: Binding<PlaygroundConfiguration.SDKType> {
        Binding(
            get: {
                self.playgroundConfiguration.sdkType
            },
            set: {
                self.playgroundConfiguration.sdkType = $0
                self.objectWillChange.send()
            }
        )
    }

    var merchant: Binding<PlaygroundConfiguration.Merchant> {
        Binding(
            get: {
                self.playgroundConfiguration.merchant
            },
            set: {
                self.playgroundConfiguration.merchant = $0
                self.objectWillChange.send()
            }
        )
    }

    var testMode: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.testMode
            },
            set: {
                self.playgroundConfiguration.testMode = $0
                self.objectWillChange.send()
            }
        )
    }

    var customPublicKey: Binding<String> {
        Binding(
            get: {
                self.playgroundConfiguration.customPublicKey
            },
            set: {
                self.playgroundConfiguration.customPublicKey = $0
                self.objectWillChange.send()
            }
        )
    }
    var customSecretKey: Binding<String> {
        Binding(
            get: {
                self.playgroundConfiguration.customSecretKey
            },
            set: {
                self.playgroundConfiguration.customSecretKey = $0
                self.objectWillChange.send()
            }
        )
    }

    var useCase: Binding<PlaygroundConfiguration.UseCase> {
        Binding(
            get: {
                self.playgroundConfiguration.useCase
            },
            set: {
                self.playgroundConfiguration.useCase = $0
                self.objectWillChange.send()
            }
        )
    }

    var email: Binding<String> {
        Binding(
            get: {
                self.playgroundConfiguration.email
            },
            set: {
                self.playgroundConfiguration.email = $0
                self.objectWillChange.send()
            }
        )
    }

    var balancesPermission: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.balancesPermission
            },
            set: {
                self.playgroundConfiguration.balancesPermission = $0
                self.objectWillChange.send()
            }
        )
    }
    var ownershipPermission: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.ownershipPermission
            },
            set: {
                self.playgroundConfiguration.ownershipPermission = $0
                self.objectWillChange.send()
            }
        )
    }
    var paymentMethodPermission: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.paymentMethodPermission
            },
            set: {
                self.playgroundConfiguration.paymentMethodPermission = $0
                self.objectWillChange.send()
            }
        )
    }
    var transactionsdPermission: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.transactionsPermission
            },
            set: {
                self.playgroundConfiguration.transactionsPermission = $0
                self.objectWillChange.send()
            }
        )
    }

    @Published var showLiveEvents: Bool = PlaygroundUserDefaults.showLiveEvents {
        didSet {
            PlaygroundUserDefaults.showLiveEvents = showLiveEvents
        }
    }

    @Published var isLoading: Bool = false

    init() {
//        self.nativeSelection = {
//            if let enableNative = PlaygroundUserDefaults.enableNative {
//                return enableNative ? .native : .web
//            } else {
//                return .automatic
//            }
//        }()
        print(PlaygroundConfiguration.shared.configurationJSONString)

    }

    func didSelectShow() {
        setup()
    }

    private func setup() {
        isLoading = true
        SetupPlayground(
            configurationDictionary: playgroundConfiguration.configurationJSONDictionary,
            enableTestMode: false,
            flow: flow.rawValue,
            email: "",
            enableNetworkingMultiSelect: false,
            enableOwnershipPermission: false,
            enableBalancesPermission: false,
            enableTransactionsPermission: false,
            customScenario: "",
            customPublicKey: "",
            customSecretKey: ""
        ) { [weak self] setupPlaygroundResponse in
            if let setupPlaygroundResponse = setupPlaygroundResponse {
                PresentFinancialConnectionsSheet(
                    setupPlaygroundResponseJSON: setupPlaygroundResponse,
                    onEvent: { event in
                        if self?.showLiveEvents == true {
                            let message = "\(event.name.rawValue); \(event.metadata.dictionary)"
                            BannerHelper.shared.showBanner(with: message, for: 3.0)
                        }
                    },
                    completionHandler: { result in
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
                )
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
    configurationDictionary: [String: Any],
    enableTestMode: Bool,
    flow: String,
    email: String,
    enableNetworkingMultiSelect: Bool,
    enableOwnershipPermission: Bool,
    enableBalancesPermission: Bool,
    enableTransactionsPermission: Bool,
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
        requestBody["enable_networking_multi_select"] = enableNetworkingMultiSelect
        requestBody["enable_ownership_permission"] = enableOwnershipPermission
        requestBody["enable_balances_permission"] = enableBalancesPermission
        requestBody["enable_transactions_permission"] = enableTransactionsPermission
        requestBody["custom_scenario"] = customScenario
        requestBody["custom_public_key"] = customPublicKey
        requestBody["custom_secret_key"] = customSecretKey
        requestBody["new_playground"] = true
        requestBody.merge(
            configurationDictionary,
            uniquingKeysWith: { _, new in return new }
        )

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
                let data = data,
                let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
            {
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        completionHandler(responseJson)
                    }
                } else {
                    DispatchQueue.main.async {
                        completionHandler(responseJson)
                    }
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
    onEvent: @escaping (FinancialConnectionsEvent) -> Void,
    completionHandler: @escaping (FinancialConnectionsSheet.Result) -> Void
) {
    if let error = setupPlaygroundResponseJSON["error"] {
        completionHandler(
            .failed(
                error: FinancialConnectionsSheetError.unknown(
                    debugDescription: error
                )
            )
        )
        return
    }
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

    let isUITest = (ProcessInfo.processInfo.environment["UITesting"] != nil)
    let financialConnectionsSheet = FinancialConnectionsSheet(
        financialConnectionsSessionClientSecret: clientSecret,
        // disable app-to-app for UI tests
        returnURL: isUITest ? nil : "financial-connections-example://redirect"
    )
    financialConnectionsSheet.onEvent = onEvent
    financialConnectionsSheet.present(
        from: UIViewController.topMostViewController()!,
        completion: { result in
            completionHandler(result)
            _ = financialConnectionsSheet  // retain the sheet
        }
    )
}
