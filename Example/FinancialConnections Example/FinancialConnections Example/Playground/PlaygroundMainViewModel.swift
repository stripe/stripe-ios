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

        var id: String {
            return rawValue
        }
    }
    @Published var flow: Flow = Flow(rawValue: PlaygroundUserDefaults.flow)! {
        didSet {
            PlaygroundUserDefaults.flow = flow.rawValue
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

    @Published var enableAppToApp: Bool = PlaygroundUserDefaults.enableAppToApp {
        didSet {
            PlaygroundUserDefaults.enableAppToApp = enableAppToApp
        }
    }

    @Published var enableTestMode: Bool = PlaygroundUserDefaults.enableTestMode {
        didSet {
            PlaygroundUserDefaults.enableTestMode = enableTestMode
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
            enableAppToApp: enableAppToApp,
            enableTestMode: enableTestMode,
            flow: flow.rawValue,
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
                        UIAlertController.showAlert(
                            title: "Success",
                            message: "\(accountInfos)"
                        )
                    case .canceled:
                        UIAlertController.showAlert(
                            title: "Cancelled"
                        )
                    case .failed(let error):
                        UIAlertController.showAlert(
                            title: "Failed",
                            message: error.localizedDescription
                        )
                    }
                }
            }
            self?.isLoading = false
        }
    }

    func didSelectClearCaches() {
        URLSession.shared.reset(completionHandler: {})
    }
}

private func SetupPlayground(
    enableAppToApp: Bool,
    enableTestMode: Bool,
    flow: String,
    customPublicKey: String,
    customSecretKey: String,
    completionHandler: @escaping ([String: String]?) -> Void
) {
    let baseURL = "https://financial-connections-playground-ios.glitch.me"
    let endpoint = "/setup_playground"
    let url = URL(string: baseURL + endpoint)!

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
        var requestBody: [String: Any] = [:]
        requestBody["enable_test_mode"] = enableTestMode
        requestBody["enable_app_to_app"] = enableAppToApp
        requestBody["flow"] = flow
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
        fatalError("Did not receive a valid client secret.")
    }
    guard let publishableKey = setupPlaygroundResponseJSON["publishable_key"] else {
        fatalError("Did not receive a valid publishable key.")
    }

    STPAPIClient.shared.publishableKey = publishableKey

    let financialConnectionsSheet = FinancialConnectionsSheet(
        financialConnectionsSessionClientSecret: clientSecret,
        returnURL: "financial-connections-example://redirect"
    )
    financialConnectionsSheet.present(
        from: UIViewController.topMostViewController()!,
        completion: { result in
            completionHandler(result)
            _ = financialConnectionsSheet  // retain the sheet
        }
    )
}
