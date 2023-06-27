//
//  LinkPayPlaygroundController.swift
//  PaymentSheet Example
//
//  Created by Vardges Avetisyan on 6/26/23.
//

//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.
import Combine
import Contacts
import PassKit
@_spi(STP) @_spi(ExperimentalPaymentSheetDecouplingAPI) @_spi(PaymentSheetSkipConfirmation) @_spi(LinkOnly) import StripePaymentSheet
import SwiftUI
import UIKit

struct LinkPayPlaygroundControllerSettings: Codable, Equatable {
    static let nsUserDefaultsKey = "LinkPayPlaygroundControllerSettings"

    enum Mode: String, PickerEnum {
        static var enumName: String { "Mode" }

        case payment
        case setup


        var displayName: String {
            switch self {
            case .payment:
                return "Payment"
            case .setup:
                return "Setup"
            }
        }
    }

    enum IntegrationType: String, PickerEnum {
        static var enumName: String { "Type" }

        // Normal: Normal client side confirmation non-deferred flow
        case normal
        /// Def CSC: Deferred client side confirmation
        case deferred_csc
        /// Def SSC: Deferred server side confirmation
        case deferred_ssc

        var displayName: String {
            switch self {
            case .normal:
                return "Client-side confirmation"
            case .deferred_csc:
                return "Deferred client side confirmation"
            case .deferred_ssc:
                return "Deferred server side confirmation"
            }
        }
    }


    var mode: Mode
    var integrationType: IntegrationType

    static func defaultValues() -> LinkPayPlaygroundControllerSettings {
        return LinkPayPlaygroundControllerSettings(
            mode: .payment,
            integrationType: .normal)
    }
}

class LinkPayPlaygroundController: ObservableObject {
    @Published var linkPayController: LinkPaymentController?
    @Published var settings: LinkPayPlaygroundControllerSettings
    @Published var currentlyRenderedSettings: LinkPayPlaygroundControllerSettings
    @Published var isLoading: Bool = false
    @Published var lastPaymentResult: PaymentSheetResult?

    var customerConfiguration: PaymentSheet.CustomerConfiguration? {
        if let customerID = customerID,
           let ephemeralKey = ephemeralKey {
            return PaymentSheet.CustomerConfiguration(
                id: customerID, ephemeralKeySecret: ephemeralKey)
        }
        return nil
    }

    var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.customer = customerConfiguration
        configuration.appearance = appearance
        configuration.returnURL = "payments-example://stripe-redirect"
        return configuration
    }

    var intentConfig: PaymentSheet.IntentConfiguration {
        let paymentMethodTypes = ["link"]

        let confirmHandler: PaymentSheet.IntentConfiguration.ConfirmHandler = { [weak self] in
            self?.confirmHandler($0, $1, $2)
        }
        switch settings.mode {
        case .payment:
            return PaymentSheet.IntentConfiguration(
                mode: .payment(amount: amount!, currency: "usd", setupFutureUsage: nil),
                paymentMethodTypes: paymentMethodTypes,
                confirmHandler: confirmHandler
            )
        case .setup:
            return PaymentSheet.IntentConfiguration(
                mode: .setup(currency: "usd", setupFutureUsage: .offSession),
                paymentMethodTypes: paymentMethodTypes,
                confirmHandler: confirmHandler
            )
        }
    }

    var clientSecret: String?
    var ephemeralKey: String?
    var customerID: String?
    var amount: Int?
    var checkoutEndpoint = "https://abundant-elderly-universe.glitch.me/checkout"
    var confirmEndpoint = "https://abundant-elderly-universe.glitch.me/confirm_intent"
    var appearance = PaymentSheet.Appearance.default

    func makeAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: "Complete", message: "Completed", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        return alertController
    }

    var rootViewController: UIViewController {
        // Hack, should do this in SwiftUI
        return UIApplication.shared.windows.first!.rootViewController!
    }

    private var subscribers: Set<AnyCancellable> = []

    init(settings: LinkPayPlaygroundControllerSettings) {

        self.settings = settings
        self.currentlyRenderedSettings = .defaultValues()

        $settings.sink { newValue in
            self.load()
        }.store(in: &subscribers)
    }

    func buildLinkPayController() {
        let lpc: LinkPaymentController

        switch self.settings.integrationType {
        case .normal:
            switch self.settings.mode {
            case .payment:
                lpc = LinkPaymentController(paymentIntentClientSecret: self.clientSecret!)
            case .setup:
                lpc = LinkPaymentController(setupIntentClientSecret: self.clientSecret!)
            }
        case .deferred_csc, .deferred_ssc:
            lpc = LinkPaymentController(intentConfiguration: intentConfig)
        }

        self.linkPayController = lpc
    }

    func didTapResetConfig() {
        self.settings = LinkPayPlaygroundControllerSettings.defaultValues()
    }

    // Completion

    func onOptionsCompletion() {
        DispatchQueue.main.async {
            // Tell our observer to refresh
            self.objectWillChange.send()
        }
    }

    func onPSFCCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {

            self.lastPaymentResult = result}
    }

    func onPSCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            
            self.lastPaymentResult = result}
    }
}
// MARK: - Backend

extension LinkPayPlaygroundController {
    @objc
    func load() {
        serializeSettingsToNSUserDefaults()
        loadBackend()
    }

    func makeRequest(with url: String, body: [String: Any], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let session = URLSession.shared
        let url = URL(string: url)!

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, response, error in
            completionHandler(data, response, error)
        }

        task.resume()
    }

    func loadBackend() {
        linkPayController = nil
        lastPaymentResult = nil
        isLoading = true
        let settingsToLoad = self.settings

        let body = [
            "mode": settings.mode.rawValue,
        ] as [String: Any]
        makeRequest(with: checkoutEndpoint, body: body) { data, response, error in
            // If the completed load state doesn't represent the current state, reload again
            if settingsToLoad != self.settings {
                DispatchQueue.main.async {
                    self.load()
                }
                return
            }
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data),
                (response as? HTTPURLResponse)?.statusCode != 400
            else {
                print(error as Any)
                DispatchQueue.main.async {
                    var errorMessage = "An error occurred communicating with the example backend."
                    if let data = data,
                       let json = try? JSONDecoder().decode([String: String].self, from: data),
                       let jsonError = json["error"] {
                        errorMessage = jsonError
                    }
                    let error = NSError(domain: "com.stripe.paymentsheetplayground", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    self.lastPaymentResult = .failed(error: error)
                    self.isLoading = false
                    self.currentlyRenderedSettings = self.settings
                }
                return
            }

            self.clientSecret = json["intentClientSecret"]
            self.ephemeralKey = json["customerEphemeralKeySecret"]
            self.customerID = json["customerId"]
            self.amount = Int(json["amount"] ?? "")
            StripeAPI.defaultPublishableKey = json["publishableKey"]

            DispatchQueue.main.async {
                self.buildLinkPayController()
                self.isLoading = false
                self.currentlyRenderedSettings = self.settings

            }
        }
    }
}


// MARK: Deferred intent callbacks
extension LinkPayPlaygroundController {

    // Deferred confirmation handler
    func confirmHandler(_ paymentMethod: STPPaymentMethod,
                        _ shouldSavePaymentMethod: Bool,
                        _ intentCreationCallback: @escaping (Result<String, Error>) -> Void) {
        switch settings.integrationType {
        case .deferred_csc:
            if settings.integrationType == .deferred_csc {
                DispatchQueue.global(qos: .background).async {
                    intentCreationCallback(.success(PaymentSheet.IntentConfiguration.COMPLETE_WITHOUT_CONFIRMING_INTENT))
                }
            }
            return
        case .deferred_ssc:
            break
        case .normal:
            assertionFailure()
        }

        enum ConfirmHandlerError: Error, LocalizedError {
            case clientSecretNotFound
            case confirmError(String)
            case unknown

            public var errorDescription: String? {
                switch self {
                case .clientSecretNotFound:
                    return "Client secret not found in response from server."
                case .confirmError(let errorMesssage):
                    return errorMesssage
                case .unknown:
                    return "An unknown error occurred."
                }
            }
        }

        let body = [
            "client_secret": clientSecret!,
            "payment_method_id": paymentMethod.stripeId,
            "mode": intentConfig.mode.requestBody,
            "return_url": configuration.returnURL ?? "",
        ] as [String: Any]

        makeRequest(with: confirmEndpoint, body: body, completionHandler: { data, response, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            else {
                if let data = data,
                   (response as? HTTPURLResponse)?.statusCode == 400,
                   let errorMessage = String(data: data, encoding: .utf8){
                    // read the error message
                    intentCreationCallback(.failure(ConfirmHandlerError.confirmError(errorMessage)))
                } else {
                    intentCreationCallback(.failure(error ?? ConfirmHandlerError.unknown))
                }
                return
            }

            guard let clientSecret = json["client_secret"] as? String else {
                intentCreationCallback(.failure(ConfirmHandlerError.clientSecretNotFound))
                return
            }

            intentCreationCallback(.success(clientSecret))
        })
    }
}


// MARK: - Helpers

extension LinkPayPlaygroundController {
    func serializeSettingsToNSUserDefaults() {
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: LinkPayPlaygroundControllerSettings.nsUserDefaultsKey)
    }

    static func settingsFromDefaults() -> LinkPayPlaygroundControllerSettings? {
        if let data = UserDefaults.standard.value(forKey: LinkPayPlaygroundControllerSettings.nsUserDefaultsKey) as? Data {
            do {
                return try JSONDecoder().decode(LinkPayPlaygroundControllerSettings.self, from: data)
            } catch {
                print("Unable to deserialize saved settings")
                UserDefaults.standard.removeObject(forKey: LinkPayPlaygroundControllerSettings.nsUserDefaultsKey)
            }
        }
        return nil
    }
}

