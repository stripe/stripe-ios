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
@_spi(STP) import StripeFinancialConnections
@_spi(STP) import StripeFinancialConnectionsLite
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

    var linkBrand: Binding<PlaygroundConfiguration.LinkBrand> {
        Binding(
            get: {
                self.playgroundConfiguration.linkBrand
            },
            set: {
                self.playgroundConfiguration.linkBrand = $0
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

    var preCollectedConsentMode: Binding<PlaygroundConfiguration.PreCollectedConsentMode> {
        Binding(
            get: { self.playgroundConfiguration.preCollectedConsentMode },
            set: {
                self.playgroundConfiguration.preCollectedConsentMode = $0
                self.objectWillChange.send()
            }
        )
    }

    var consentLocale: Binding<String> { binding(\.consentLocale) }
    var manualConsentID: Binding<String> { binding(\.manualConsentID) }
    var manualConsentCollectedAt: Binding<String> { binding(\.manualConsentCollectedAt) }
    var accountID: Binding<String> { binding(\.accountID) }

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

    var fcLiteSecureWebview: Binding<Bool> {
        Binding(
            get: {
                self.playgroundConfiguration.fcLiteSecureWebview
            },
            set: {
                self.playgroundConfiguration.fcLiteSecureWebview = $0
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
    @Published var pendingConsent: IssuedConsent?

    private var consentAcceptanceHandler: ((Bool) -> Void)?
    private var consentAcceptanceResult: Bool?

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

    private func binding<T>(_ keyPath: ReferenceWritableKeyPath<PlaygroundConfiguration, T>) -> Binding<T> {
        Binding(
            get: { self.playgroundConfiguration[keyPath: keyPath] },
            set: {
                self.playgroundConfiguration[keyPath: keyPath] = $0
                self.objectWillChange.send()
            }
        )
    }

    func resolvePendingConsent(accepted: Bool) {
        consentAcceptanceResult = accepted
        pendingConsent = nil
    }

    func didDismissConsentSheet() {
        guard let accepted = consentAcceptanceResult else { return }
        consentAcceptanceResult = nil
        let handler = consentAcceptanceHandler
        consentAcceptanceHandler = nil
        handler?(accepted)
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
        switch playgroundConfiguration.preCollectedConsentMode {
        case .off:
            launchSession(
                configuration: playgroundConfiguration.configurationDictionary,
                evidence: nil
            )
        case .manual:
            launchStandalone(evidence: manualEvidence, accountHolder: manualAccountHolder)
        case .guided:
            createGuidedConsent()
        }
    }

    private var manualEvidence: FinancialConnectionsPreCollectedConsent? {
        guard
            !playgroundConfiguration.manualConsentID.isEmpty,
            let collectedAt = Int(playgroundConfiguration.manualConsentCollectedAt)
        else { return nil }
        return FinancialConnectionsPreCollectedConsent(
            consent: playgroundConfiguration.manualConsentID,
            collectedAt: collectedAt
        )
    }

    private var manualAccountHolder: AccountHolder? {
        switch playgroundConfiguration.useCase {
        case .token:
            guard !playgroundConfiguration.accountID.isEmpty else { return nil }
            return .account(playgroundConfiguration.accountID)
        case .data, .paymentIntent:
            guard !playgroundConfiguration.customerId.isEmpty else { return nil }
            return .customer(playgroundConfiguration.customerId)
        }
    }

    private func createGuidedConsent() {
        isLoading = true
        let holderType: AccountHolderType = playgroundConfiguration.useCase == .token ? .account : .customer
        CreateAccountHolder(type: holderType, configuration: playgroundConfiguration.configurationDictionary) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                self.finishLoading(with: error)
            case .success(let holder):
                CreateConsent(
                    accountHolder: holder,
                    locale: self.playgroundConfiguration.consentLocale,
                    configuration: self.playgroundConfiguration.configurationDictionary
                ) { result in
                    switch result {
                    case .failure(let error):
                        self.finishLoading(with: error)
                    case .success(let consent):
                        self.isLoading = false
                        self.pendingConsent = consent
                        self.consentAcceptanceHandler = { [weak self] accepted in
                            guard let self else { return }
                            guard accepted else { return }
                            let collectedAt = Int(Date().timeIntervalSince1970)
                            guard consent.expiresAt > collectedAt else {
                                self.finishLoading(with: PlaygroundRequestError.server(
                                    "Consent expired before it could be accepted. Launch again to request new consent."
                                ))
                                return
                            }
                            let evidence = FinancialConnectionsPreCollectedConsent(
                                consent: consent.id,
                                collectedAt: collectedAt
                            )
                            self.launchStandalone(evidence: evidence, accountHolder: holder)
                        }
                    }
                }
            }
        }
    }

    private func launchStandalone(
        evidence: FinancialConnectionsPreCollectedConsent?,
        accountHolder: AccountHolder?
    ) {
        var configuration = playgroundConfiguration.configurationDictionary
        if let accountHolder { configuration["account_holder"] = accountHolder.dictionary }
        switch playgroundConfiguration.useCase {
        case .data, .token:
            launchSession(configuration: configuration, evidence: evidence)
        case .paymentIntent:
            launchBankAccountIntent(configuration: configuration, evidence: evidence)
        }
    }

    private func launchSession(configuration: [String: Any], evidence: FinancialConnectionsPreCollectedConsent?) {
        isLoading = true
        SetupPlayground(configurationDictionary: configuration) { [weak self] response in
            guard let self, let response else {
                self?.finishLoading(with: PlaygroundRequestError.invalidResponse)
                return
            }
            self.isLoading = false
            var events: [String] = []
            if evidence == nil {
                PresentFinancialConnectionsSheetWithoutPreCollectedConsent(
                    useCase: self.playgroundConfiguration.useCase,
                    stripeAccount: self.playgroundConfiguration.merchant.stripeAccount,
                    setupPlaygroundResponseJSON: response,
                    style: self.playgroundConfiguration.style,
                    linkBrand: self.playgroundConfiguration.linkBrand,
                    onEvent: { event in
                        if self.liveEvents.wrappedValue {
                            BannerHelper.shared.showBanner(
                                with: "\(event.name.rawValue); \(event.metadata.dictionary)",
                                for: 3.0
                            )
                        }
                        events.append(event.name.rawValue)
                    },
                    completionHandler: { result in self.handleHostControllerResult(result, events: events) }
                )
                return
            }
            PresentFinancialConnectionsSheet(
                useCase: self.playgroundConfiguration.useCase,
                stripeAccount: self.playgroundConfiguration.merchant.stripeAccount,
                setupPlaygroundResponseJSON: response,
                style: self.playgroundConfiguration.style,
                linkBrand: self.playgroundConfiguration.linkBrand,
                preCollectedConsent: evidence,
                onEvent: { event in
                    if self.liveEvents.wrappedValue {
                        BannerHelper.shared.showBanner(
                            with: "\(event.name.rawValue); \(event.metadata.dictionary)",
                            for: 3.0
                        )
                    }
                    events.append(event.name.rawValue)
                },
                completionHandler: { result in self.handleSessionResult(result, events: events) }
            )
        }
    }

    private func handleHostControllerResult(
        _ result: HostControllerResult,
        events: [String]
    ) {
        switch result {
        case .completed(let flow):
            switch flow {
            case .financialConnections(let session):
                handleSessionResult(.completed(session: session), events: events)
            case .instantDebits(let linkedBank):
                let sessionId = linkedBank.linkAccountSessionId ?? "N/a"
                let bankAccount: String
                if let bankName = linkedBank.bankName, let last4 = linkedBank.last4 {
                    bankAccount = "\(bankName) ....\(last4)"
                } else {
                    bankAccount = "Bank details unavailable"
                }
                let message = """
                \(bankAccount)

                session_id=\(sessionId)
                payment_method_id=\(linkedBank.paymentMethod.id)
                events=\(events.joined(separator: ","))
                """
                sessionOutput[.message] = message
                sessionOutput[.sessionId] = sessionId
                UIAlertController.showAlert(title: "Success", message: message)
            @unknown default:
                UIAlertController.showAlert(message: "Unknown payment method flow")
            }
        case .canceled:
            UIAlertController.showAlert(title: "Cancelled")
        case .failed(let error):
            let message: String
            if case .unknown(let debugDescription) = error as? FinancialConnectionsSheetError {
                message = debugDescription
            } else {
                message = error.localizedDescription
            }
            UIAlertController.showAlert(title: "Failed", message: message)
        }
    }

    private func launchBankAccountIntent(
        configuration: [String: Any],
        evidence: FinancialConnectionsPreCollectedConsent?
    ) {
        isLoading = true
        CreateBankAccountIntent(configuration: configuration) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .failure(let error): self.finishLoading(with: error)
            case .success(let intent):
                PresentBankAccountCollector(
                    intent: intent,
                    stripeAccount: self.playgroundConfiguration.merchant.stripeAccount,
                    email: self.playgroundConfiguration.email,
                    evidence: evidence
                )
            }
        }
    }

    private func handleSessionResult(
        _ result: FinancialConnectionsSheet.Result,
        events: [String]
    ) {
        switch result {
        case .completed(let session):
            let accounts = session.accounts.data.filter { $0.last4 != nil }
            let accountInfos = accounts.map { "\($0.institutionName) ....\($0.last4!)" }
            sessionOutput[.sessionId] = session.id
            sessionOutput[.accountNames] = session.accounts.data.map { $0.displayName ?? "N/A" }.joinedUnlessEmpty
            sessionOutput[.accountIds] = session.accounts.data.map(\.id).joinedUnlessEmpty
            let message = """
            \(accountInfos)

            session_id=\(session.id)
            account_names=\(session.accounts.data.map { $0.displayName ?? "N/A" })
            account_ids=\(session.accounts.data.map(\.id))
            events=\(events.joined(separator: ","))
            """
            sessionOutput[.message] = message
            UIAlertController.showAlert(title: "Success", message: message)
        case .canceled:
            UIAlertController.showAlert(title: "Cancelled")
        case .failed(let error):
            UIAlertController.showAlert(title: "Failed", message: error.localizedDescription)
        default:
            UIAlertController.showAlert(message: "Unknown result")
        }
    }

    private func finishLoading(with error: Error) {
        isLoading = false
        UIAlertController.showAlert(title: "Playground request failed", message: error.localizedDescription)
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

private enum AccountHolderType: String, Decodable {
    case customer
    case account
}

private struct AccountHolder: Decodable {
    let type: AccountHolderType
    let customer: String?
    let account: String?

    static func customer(_ id: String) -> Self {
        Self(type: .customer, customer: id, account: nil)
    }

    static func account(_ id: String) -> Self {
        Self(type: .account, customer: nil, account: id)
    }

    var dictionary: [String: Any] {
        switch type {
        case .customer: return ["type": type.rawValue, "customer": customer ?? ""]
        case .account: return ["type": type.rawValue, "account": account ?? ""]
        }
    }
}

private struct CreateAccountHolderResponse: Decodable {
    let accountHolder: AccountHolder
}

struct IssuedConsent: Decodable, Identifiable {
    let id: String
    let consentText: String
    let locale: String
    let expiresAt: Int

    var attributedText: AttributedString {
        (try? AttributedString(markdown: consentText)) ?? AttributedString(consentText)
    }
}

private struct BankAccountIntentResponse: Decodable {
    let clientSecret: String
    let publishableKey: String
}

private enum PlaygroundRequestError: LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "The Playground server returned an invalid response."
        case .server(let message): return message
        }
    }
}

private struct PlaygroundErrorResponse: Decodable {
    let error: String
}

private func CreateAccountHolder(
    type: AccountHolderType,
    configuration: [String: Any],
    completion: @escaping (Result<AccountHolder, Error>) -> Void
) {
    var request = configuration
    request["type"] = type.rawValue
    PostPlayground(endpoint: "/create_accountholder", body: request) { (result: Result<CreateAccountHolderResponse, Error>) in
        completion(result.map(\.accountHolder))
    }
}

private func CreateConsent(
    accountHolder: AccountHolder,
    locale: String,
    configuration: [String: Any],
    completion: @escaping (Result<IssuedConsent, Error>) -> Void
) {
    var request = configuration
    request["account_holder"] = accountHolder.dictionary
    if !locale.isEmpty { request["locale"] = locale }
    PostPlayground(endpoint: "/create_consent", body: request, completion: completion)
}

private func CreateBankAccountIntent(
    configuration: [String: Any],
    completion: @escaping (Result<BankAccountIntentResponse, Error>) -> Void
) {
    PostPlayground(endpoint: "/create_payment_intent", body: configuration, completion: completion)
}

private func PostPlayground<Response: Decodable>(
    endpoint: String,
    body: [String: Any],
    completion: @escaping (Result<Response, Error>) -> Void
) {
    let baseURL = "https://ios-financial-connections-playground.stripedemos.com"
    var request = URLRequest(url: URL(string: baseURL + endpoint)!)
    request.httpMethod = "POST"
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard error == nil, let data, let response = response as? HTTPURLResponse else {
            DispatchQueue.main.async {
                completion(.failure(PlaygroundRequestError.invalidResponse))
            }
            return
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if !(200..<300).contains(response.statusCode) {
            let message = (try? decoder.decode(PlaygroundErrorResponse.self, from: data).error) ?? "Request failed."
            DispatchQueue.main.async {
                completion(.failure(PlaygroundRequestError.server(message)))
            }
            return
        }
        do {
            let decoded = try decoder.decode(Response.self, from: data)
            DispatchQueue.main.async { completion(.success(decoded)) }
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }.resume()
}

private func PresentBankAccountCollector(
    intent: BankAccountIntentResponse,
    stripeAccount: String?,
    email: String,
    evidence: FinancialConnectionsPreCollectedConsent?
) {
    STPAPIClient.shared.publishableKey = intent.publishableKey
    let collector = STPBankAccountCollector()
    collector.apiClient.stripeAccount = stripeAccount
    let params = STPCollectBankAccountParams.collectUSBankAccountParams(
        with: "Financial Connections Example",
        email: email.isEmpty ? nil : email
    )
    let presenter = UIViewController.topMostViewController()!
    let completion: (AnyObject?, NSError?) -> Void = { collectedIntent, error in
        if let error {
            UIAlertController.showAlert(title: "Failed", message: error.localizedDescription)
        } else if collectedIntent != nil {
            UIAlertController.showAlert(title: "Success")
        }
        _ = collector
    }
    collector.collectBankAccountForPayment(
        clientSecret: intent.clientSecret,
        returnURL: PlaygroundViewModel.returnUrl,
        params: params,
        preCollectedConsent: evidence,
        from: presenter,
        onEvent: nil
    ) { paymentIntent, error in
        completion(paymentIntent, error)
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

private func PresentFinancialConnectionsSheetWithoutPreCollectedConsent(
    useCase: PlaygroundConfiguration.UseCase,
    stripeAccount: String?,
    setupPlaygroundResponseJSON: [String: String],
    style: PlaygroundConfiguration.Style,
    linkBrand: PlaygroundConfiguration.LinkBrand,
    onEvent: @escaping (FinancialConnectionsEvent) -> Void,
    completionHandler: @escaping (HostControllerResult) -> Void
) {
    if let error = setupPlaygroundResponseJSON["error"] {
        completionHandler(
            .failed(error: FinancialConnectionsSheetError.unknown(debugDescription: error))
        )
        return
    }
    guard let clientSecret = setupPlaygroundResponseJSON["client_secret"] else {
        completionHandler(
            .failed(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Server returned no client_secret. Try clearing 'Custom Keys' or delete & re-install the app."
            ))
        )
        return
    }
    guard let publishableKey = setupPlaygroundResponseJSON["publishable_key"] else {
        completionHandler(
            .failed(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Server returned no publishable_key. Try clearing 'Custom Keys' or delete & re-install the app."
            ))
        )
        return
    }

    STPAPIClient.shared.publishableKey = publishableKey

    let isUITest = (ProcessInfo.processInfo.environment["UITesting"] != nil)
    var configuration = FinancialConnectionsSheet.Configuration()
    configuration.style = style.configurationValue
    configuration.linkBrand = linkBrand == .on ? .onelink : nil
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

private func PresentFinancialConnectionsSheet(
    useCase: PlaygroundConfiguration.UseCase,
    stripeAccount: String?,
    setupPlaygroundResponseJSON: [String: String],
    style: PlaygroundConfiguration.Style,
    linkBrand: PlaygroundConfiguration.LinkBrand,
    preCollectedConsent: FinancialConnectionsPreCollectedConsent?,
    onEvent: @escaping (FinancialConnectionsEvent) -> Void,
    completionHandler: @escaping (FinancialConnectionsSheet.Result) -> Void
) {
    if let error = setupPlaygroundResponseJSON["error"] {
        completionHandler(
            .failed(error: FinancialConnectionsSheetError.unknown(debugDescription: error))
        )
        return
    }
    guard let clientSecret = setupPlaygroundResponseJSON["client_secret"] else {
        completionHandler(
            .failed(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Server returned no client_secret. Try clearing 'Custom Keys' or delete & re-install the app."
            ))
        )
        return
    }
    guard let publishableKey = setupPlaygroundResponseJSON["publishable_key"] else {
        completionHandler(
            .failed(error: FinancialConnectionsSheetError.unknown(
                debugDescription: "Server returned no publishable_key. Try clearing 'Custom Keys' or delete & re-install the app."
            ))
        )
        return
    }

    STPAPIClient.shared.publishableKey = publishableKey

    let isUITest = (ProcessInfo.processInfo.environment["UITesting"] != nil)
    var configuration = FinancialConnectionsSheet.Configuration()
    configuration.style = style.configurationValue
    configuration.linkBrand = linkBrand == .on ? .onelink : nil
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
            let result = await financialConnectionsSheet.presentForToken(
                from: topMostViewController,
                preCollectedConsent: preCollectedConsent
            )
            completionHandler({
                switch result {
                case .completed(result: let tuple):
                    return .completed(session: tuple.session)
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
            preCollectedConsent: preCollectedConsent,
            completion: { (result: FinancialConnectionsSheet.Result) in
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

    if config.linkBrand == .on {
        configuration.link.brand = .onelink
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
