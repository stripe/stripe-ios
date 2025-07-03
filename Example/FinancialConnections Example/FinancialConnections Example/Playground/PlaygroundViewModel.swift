//
//  PlaygroundViewModel.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/5/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Combine
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) @_spi(v25) import StripeFinancialConnections
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
import SwiftUI
import UIKit

final class PlaygroundViewModel: ObservableObject {
    static let returnUrl = "financial-connections-example://redirect"

    enum SessionOutputField {
        case message
        case sessionId
        case accountIds
        case accountNames
    }

    let playgroundConfiguration = PlaygroundConfiguration.shared

    var integrationType: Binding<PlaygroundConfiguration.IntegrationType> {
        Binding(
            get: {
                self.playgroundConfiguration.integrationType
            },
            set: { newValue in
                self.playgroundConfiguration.integrationType = newValue

                if newValue == .paymentElement, self.playgroundConfiguration.merchant.customId == .default {
                    // Set to Netowrking merchant when switching to Payment Element.
                    if let networkingMerchant = self.playgroundConfiguration.merchants.first(where: { $0.customId == .networking }) {
                        self.playgroundConfiguration.merchant = networkingMerchant
                    }
                }

                self.objectWillChange.send()
            }
        )
    }

    var experience: Binding<PlaygroundConfiguration.Experience> {
        Binding(
            get: {
                self.playgroundConfiguration.experience
            },
            set: { newValue in
                self.playgroundConfiguration.experience = newValue
                if newValue == .instantBankPayment {
                    // Instant debits only supports the payment intent use case.
                    self.playgroundConfiguration.useCase = .paymentIntent
                }
                self.objectWillChange.send()
            }
        )
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

    var phone: Binding<String> {
        Binding(
            get: {
                self.playgroundConfiguration.phone
            },
            set: {
                self.playgroundConfiguration.phone = $0
                self.objectWillChange.send()
            }
        )
    }

    var customerId: Binding<String> {
        Binding(
            get: {
                self.playgroundConfiguration.customerId
            },
            set: {
                self.playgroundConfiguration.customerId = $0
                self.objectWillChange.send()
            }
        )
    }

    var relinkAuthorization: Binding<String> {
        Binding(
            get: {
                self.playgroundConfiguration.relinkAuthorization
            },
            set: {
                self.playgroundConfiguration.relinkAuthorization = $0
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
    var transactionsPermission: Binding<Bool> {
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

    var liveEvents: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.liveEvents
            },
            set: {
                self.playgroundConfiguration.liveEvents = $0
                self.objectWillChange.send()
            }
        )
    }

    var style: Binding<PlaygroundConfiguration.Style> {
        Binding(
            get: {
                self.playgroundConfiguration.style
            },
            set: {
                self.playgroundConfiguration.style = $0
                self.objectWillChange.send()
            }
        )
    }

    @Published var showConfigurationView = false
    private(set) lazy var playgroundConfigurationViewModel: PlaygroundManageConfigurationViewModel = {
       return PlaygroundManageConfigurationViewModel(
        playgroundConfiguration: playgroundConfiguration,
        didSelectClose: { [weak self] in
            self?.showConfigurationView = false
        }
       )
    }()

    @Published var isLoading: Bool = false
    @Published var sessionOutput: [SessionOutputField: String] = [:]

    private var cancellables: Set<AnyCancellable> = []

    init() {
        print(PlaygroundConfiguration.shared.configurationString)
        playgroundConfigurationViewModel
            .objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func didSelectShow() {
        let useFCLite = playgroundConfiguration.sdkType == .fcLite
        FinancialConnectionsSDKAvailability.localFcLiteOverride = useFCLite

        switch playgroundConfiguration.integrationType {
        case .standalone:
            if useFCLite {
                setupFcLite()
            } else {
                setupStandalone()
            }
        case .paymentElement:
            setupPaymentElement()
        }
    }

    private func setupPaymentElement() {
        func presentAlert(for error: PaymentSheetError) {
            var title: String = "Error"
            let message: String?

            switch error {
            case .invalidResponse:
                message = "Invalid server response"
            case .decodingError(let error):
                message = "Decoding error: \(error)"
            case .paymentSheetCanceled:
                title = "Canceled"
                message = nil
            case .paymentSheetError(let error):
                message = "Error from payment sheet: \(error)"
            }

            DispatchQueue.main.async {
                UIAlertController.showAlert(title: title, message: message)
            }
        }

        isLoading = true
        CreatePaymentIntent(
            configuration: playgroundConfiguration.configurationDictionary
        ) { [weak self] createPaymentIntentResult in
            guard let self else { return }
            switch createPaymentIntentResult {
            case .success(let paymentIntent):
                PresentPaymentSheet(
                    paymentIntent: paymentIntent,
                    config: self.playgroundConfiguration,
                    completion: { paymentSheetResult in
                        switch paymentSheetResult {
                        case .success:
                            UIAlertController.showAlert(title: "Payment success")
                        case .failure(let error):
                            presentAlert(for: error)
                        }
                    }
                )
            case .failure(let error):
                presentAlert(for: error)
            }

            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    private func setupStandalone() {
        isLoading = true
        SetupPlayground(
            configurationDictionary: playgroundConfiguration.configurationDictionary
        ) { [weak self] setupPlaygroundResponse in
            guard let self else { return }
            if let setupPlaygroundResponse = setupPlaygroundResponse {
                var onEventEvents: [String] = []
                PresentFinancialConnectionsSheet(
                    useCase: self.playgroundConfiguration.useCase,
                    stripeAccount: self.playgroundConfiguration.merchant.stripeAccount,
                    setupPlaygroundResponseJSON: setupPlaygroundResponse,
                    style: self.playgroundConfiguration.style,
                    onEvent: { event in
                        if self.liveEvents.wrappedValue == true {
                            let message = "\(event.name.rawValue); \(event.metadata.dictionary)"
                            BannerHelper.shared.showBanner(with: message, for: 3.0)
                        }
                        onEventEvents.append(event.name.rawValue)
                    },
                    completionHandler: { [weak self] result in
                        switch result {
                        case .completed(let flow):
                            switch flow {
                            case .financialConnections(let session):
                                let accounts = session.accounts.data.filter { $0.last4 != nil }
                                let accountInfos = accounts.map { "\($0.institutionName) ....\($0.last4!)" }

                                let sessionId = session.id
                                let accountNames = session.accounts.data.map({ $0.displayName ?? "N/A" })
                                let accountIds = session.accounts.data.map({ $0.id })

                                // WARNING: the "events" output is used for end-to-end tests so be careful modifying it
                                let sessionInfo =
                                """
                                session_id=\(sessionId)
                                account_names=\(accountNames)
                                account_ids=\(accountIds)
                                events=\(onEventEvents.joined(separator: ","))
                                """

                                let message = "\(accountInfos)\n\n\(sessionInfo)"
                                self?.sessionOutput[.message] = message
                                self?.sessionOutput[.sessionId] = sessionId
                                self?.sessionOutput[.accountNames] = accountNames.joinedUnlessEmpty
                                self?.sessionOutput[.accountIds] = accountIds.joinedUnlessEmpty

                                UIAlertController.showAlert(
                                    title: "Success",
                                    message: message
                                )
                            case .instantDebits(let linkedBank):
                                let sessionId = linkedBank.linkAccountSessionId ?? "N/a"
                                let paymentMethodId = linkedBank.paymentMethod.id
                                let bankAccount: String
                                if let bankName = linkedBank.bankName, let last4 = linkedBank.last4 {
                                    bankAccount = "\(bankName) ....\(last4)"
                                } else {
                                    bankAccount = "Bank details unavailable"
                                }

                                let sessionInfo =
                                """
                                session_id=\(sessionId)
                                payment_method_id=\(paymentMethodId)
                                events=\(onEventEvents.joined(separator: ","))
                                """

                                let message = "\(bankAccount)\n\n\(sessionInfo)"
                                self?.sessionOutput[.message] = message
                                self?.sessionOutput[.sessionId] = sessionId

                                UIAlertController.showAlert(
                                    title: "Success",
                                    message: message
                                )
                            @unknown default:
                                UIAlertController.showAlert(
                                    message: "Unknown payment method flow"
                                )
                            }
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
                        @unknown default:
                            UIAlertController.showAlert(
                                message: "Unknown result"
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
            self.isLoading = false
        }
    }

    private func setupFcLite() {
        isLoading = true
        SetupPlayground(
            configurationDictionary: playgroundConfiguration.configurationDictionary
        ) { [weak self] setupPlaygroundResponse in
            guard let self else { return }
            if let setupPlaygroundResponse {
                if let error = setupPlaygroundResponse["error"] {
                    UIAlertController.showAlert(
                        title: "Setup playground failed",
                        message: error
                    )
                    return
                }

                guard let clientSecret = setupPlaygroundResponse["client_secret"] else {
                    UIAlertController.showAlert(
                        title: "Setup playground failed",
                        message: "No client_secret in response"
                    )
                    return
                }
                guard let publishableKey = setupPlaygroundResponse["publishable_key"] else {
                    UIAlertController.showAlert(
                        title: "Setup playground failed",
                        message: "No publishable_key in response"
                    )
                    return
                }

                STPAPIClient.shared.publishableKey = publishableKey
                DispatchQueue.main.async {
                    let topMostViewController = UIViewController.topMostViewController()!
                    let fc = FinancialConnectionsLite(
                        clientSecret: clientSecret,
                        returnUrl: URL(string: Self.returnUrl)!
                    )
                    fc.present(from: topMostViewController) { [weak self] result in
                        switch result {
                        case .completed(let completed):
                            switch completed {
                            case .financialConnections(let linkedBank):
                                let sessionId = linkedBank.sessionId
                                let accountId = linkedBank.accountId
                                let bankAccount: String
                                if let bankName = linkedBank.bankName, let last4 = linkedBank.last4 {
                                    bankAccount = "\(bankName) ....\(last4)"
                                } else {
                                    bankAccount = "Bank details unavailable"
                                }

                                let sessionInfo =
                                    """
                                    session_id=\(sessionId)
                                    account_id=\(accountId)
                                    """

                                let message = "\(bankAccount)\n\n\(sessionInfo)"
                                self?.sessionOutput[.message] = message
                                self?.sessionOutput[.sessionId] = sessionId
                                self?.sessionOutput[.accountIds] = accountId

                                UIAlertController.showAlert(
                                    title: "Success",
                                    message: message
                                )
                            case .instantDebits(let linkedBank):
                                let sessionId = linkedBank.linkAccountSessionId ?? "N/a"
                                let paymentMethodId = linkedBank.paymentMethod.id
                                let bankAccount: String
                                if let bankName = linkedBank.bankName, let last4 = linkedBank.last4 {
                                    bankAccount = "\(bankName) ....\(last4)"
                                } else {
                                    bankAccount = "Bank details unavailable"
                                }

                                let sessionInfo =
                                    """
                                    session_id=\(sessionId)
                                    payment_method_id=\(paymentMethodId)
                                    """

                                let message = "\(bankAccount)\n\n\(sessionInfo)"
                                self?.sessionOutput[.message] = message
                                self?.sessionOutput[.sessionId] = sessionId

                                UIAlertController.showAlert(
                                    title: "Success",
                                    message: message
                                )
                            @unknown default:
                                UIAlertController.showAlert(
                                    message: "Unknown payment method flow"
                                )
                            }
                        case .cancelled:
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
            } else {
                UIAlertController.showAlert(
                    title: "Playground App Setup Failed",
                    message: "Try clearing 'Custom Keys' or delete & re-install the app."
                )
            }
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    func didSelectClearCaches() {
        URLSession.shared.reset(completionHandler: {})
    }

    func copySessionId() {
        guard let sessionId = sessionOutput[.sessionId] else { return }
        UIPasteboard.general.string = sessionId
    }

    func copyAccountNames() {
        guard let accountNames = sessionOutput[.accountNames] else { return }
        UIPasteboard.general.string = accountNames
    }

    func copyAccountIds() {
        guard let accountIds = sessionOutput[.accountIds] else { return }
        UIPasteboard.general.string = accountIds
    }
}

private func SetupPlayground(
    configurationDictionary: [String: Any],
    completionHandler: @escaping ([String: String]?) -> Void
) {
    if
        (configurationDictionary["test_mode"] as? Bool) != true,
        (configurationDictionary["email"] as? String) == "test@test.com"
    {
        assertionFailure("test@test.com will not work with livemode, it will return rate limit exceeded")
    }

    let baseURL = "https://ios-financial-connections-playground.stripedemos.com"
    let endpoint = "/setup_playground"
    let url = URL(string: baseURL + endpoint)!

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = {
        var requestBody: [String: Any] = [:]
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
    useCase: PlaygroundConfiguration.UseCase,
    stripeAccount: String?,
    setupPlaygroundResponseJSON: [String: String],
    style: PlaygroundConfiguration.Style,
    onEvent: @escaping (FinancialConnectionsEvent) -> Void,
    completionHandler: @escaping (HostControllerResult) -> Void
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
    var configuration = FinancialConnectionsSheet.Configuration()
    configuration.style = style.configurationValue
    let financialConnectionsSheet = FinancialConnectionsSheet(
        financialConnectionsSessionClientSecret: clientSecret,
        // disable app-to-app for UI tests
        returnURL: isUITest ? nil : PlaygroundViewModel.returnUrl,
        configuration: configuration
    )
    financialConnectionsSheet.apiClient.stripeAccount = stripeAccount
    financialConnectionsSheet.onEvent = onEvent
    let topMostViewController = UIViewController.topMostViewController()!
    if useCase == .token {
        // For testing: Use async API for token presentation
        Task { @MainActor in
            let result = await financialConnectionsSheet.presentForToken(from: topMostViewController)
            completionHandler({
                switch result {
                case .completed(result: let tuple):
                    return .completed(.financialConnections(tuple.session))
                case .canceled:
                    return .canceled
                case .failed(error: let error):
                    return .failed(error: error)
                }
            }())
            _ = financialConnectionsSheet  // retain the sheet
        }
    } else {
        financialConnectionsSheet.present(
            from: topMostViewController,
            completion: { (result: HostControllerResult) in
                completionHandler(result)
                _ = financialConnectionsSheet  // retain the sheet
            }
        )
    }
}

private func CreatePaymentIntent(
    configuration: [String: Any],
    completion: @escaping (Result<CreatePaymentIntentResponse, PaymentSheetError>) -> Void
) {
    let baseURL = "https://ios-financial-connections-playground.stripedemos.com"
    let endpoint = "/create_payment_intent"
    let url = URL(string: baseURL + endpoint)!

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try! JSONSerialization.data(
        withJSONObject: configuration,
        options: .prettyPrinted
    )
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    URLSession.shared.dataTask(
        with: urlRequest,
        completionHandler: { data, _, error in
            guard error == nil, let data else {
                completion(.failure(.invalidResponse))
                return
            }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let paymentIntent = try decoder.decode(CreatePaymentIntentResponse.self, from: data)
                completion(.success(paymentIntent))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
    )
    .resume()
}

struct CreatePaymentIntentResponse: Decodable {
    let id: String
    let clientSecret: String
    let publishableKey: String
    let customerId: String
    let ephemeralKey: String
    let amount: Int
    let currency: String
}

enum PaymentSheetError: Error {
    case invalidResponse
    case decodingError(Error)
    case paymentSheetCanceled
    case paymentSheetError(Error)
}

private func PresentPaymentSheet(
    paymentIntent: CreatePaymentIntentResponse,
    config: PlaygroundConfiguration,
    completion: @escaping (Result<String, PaymentSheetError>) -> Void
) {
    /// https://docs.stripe.com/payments/accept-a-payment?platform=ios&ui=payment-sheet
    STPAPIClient.shared.publishableKey = paymentIntent.publishableKey

    var configuration = PaymentSheet.Configuration()
    configuration.merchantDisplayName = "Financial Connections Example"
    configuration.customer = .init(
        id: paymentIntent.customerId,
        ephemeralKeySecret: paymentIntent.ephemeralKey
    )
    configuration.allowsDelayedPaymentMethods = true
    configuration.defaultBillingDetails.email = config.email
    configuration.defaultBillingDetails.phone = config.phone

    switch config.style {
    case .automatic: configuration.style = .automatic
    case .alwaysLight: configuration.style = .alwaysLight
    case .alwaysDark: configuration.style = .alwaysDark
    }

    let isUITest = (ProcessInfo.processInfo.environment["UITesting"] != nil)
    // disable app-to-app for UI tests
    configuration.returnURL = isUITest ? nil : PlaygroundViewModel.returnUrl

    let paymentSheet = PaymentSheet(
        paymentIntentClientSecret: paymentIntent.clientSecret,
        configuration: configuration
    )

    DispatchQueue.main.async {
        let topMostViewController = UIViewController.topMostViewController()!
        paymentSheet.present(
            from: topMostViewController,
            completion: { paymentSheetResult in
                switch paymentSheetResult {
                case .completed:
                    completion(.success("Payment completed"))
                case .canceled:
                    completion(.failure(.paymentSheetCanceled))
                case .failed(let error):
                    completion(.failure(.paymentSheetError(error)))
                }
            }
        )
    }
}

private extension [String] {
    /// Returns nil if the array is empty, otherwise joins the array values with a new line.
    var joinedUnlessEmpty: String? {
        isEmpty ? nil : joined(separator: "\n")
    }
}
