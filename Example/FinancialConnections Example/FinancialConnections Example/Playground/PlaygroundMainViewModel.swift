//
//  PlaygroundMainViewModel.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import StripeFinancialConnections

final class PlaygroundMainViewModel: ObservableObject {
    
    @Published var enableTestMode: Bool = false
    
    init() {
        
    }
    
    func didSelectShow() {
        setup()
    }
    
    private func setup() {
        SetupPlayground(
            enableTestMode: enableTestMode
        ) { setupPlaygroundResponse in
            if let setupPlaygroundResponse = setupPlaygroundResponse {
                PresentFinancialConnectionsSheet(
                    setupPlaygroundResponseJSON: setupPlaygroundResponse
                ) {
                    
                }
            } else {
                
            }
        }
    }
}

private func SetupPlayground(
    enableTestMode: Bool,
    completionHandler: @escaping ([String:String]?) -> Void
) {
    let baseURL = "https://financial-connections-playground-ios.glitch.me"
    let endpoint = "/setup_playground"
    let url = URL(string: baseURL + endpoint)!
    
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
        var requestBody: [String:Any] = [:]
        requestBody["enable_test_mode"] = enableTestMode
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
            if
                error == nil,
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
    setupPlaygroundResponseJSON: [String:String],
    completionHandler: @escaping () -> Void
) {
    guard let clientSecret = setupPlaygroundResponseJSON["client_secret"] else {
        assertionFailure("Did not receive a valid client secret.")
        return
    }
    guard let publishableKey = setupPlaygroundResponseJSON["publishable_key"]  else {
        assertionFailure("Did not receive a valid publishable key.")
        return
    }
    
    STPAPIClient.shared.publishableKey = publishableKey

    let financialConnectionsSheet = FinancialConnectionsSheet(
        financialConnectionsSessionClientSecret: clientSecret,
        returnURL: "financial-connections-example://redirect"
    )
    financialConnectionsSheet.present(
        from: UIViewController.topMostViewController()!,
        completion: { result in
            switch result {
            case .completed(session: let session):
                let accounts = session.accounts.data.filter { $0.last4 != nil }
                let accountInfos = accounts.map { "\($0.institutionName) ....\($0.last4!)" }
                print(accountInfos)
//                self?.displayAlert("Completed with \(accountInfos.joined(separator: "\n")) accounts")
            case .canceled:
                print("cancelled")
//                self?.displayAlert("Canceled!")
            case .failed(let error):
                print(error)
            }
            _ = financialConnectionsSheet // retain the sheet
        })
}
