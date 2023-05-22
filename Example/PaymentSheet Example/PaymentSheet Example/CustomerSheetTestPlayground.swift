//
//  CustomerSheetTestPlayground.swift
//  PaymentSheet Example
//
//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` or @_spi(PrivateBetaCustomerSheet) in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.

import Contacts
import Foundation
import PassKit
@_spi(PrivateBetaCustomerSheet) import StripePaymentSheet
import SwiftUI
import UIKit

class CustomerSheetTestPlayground: UIViewController {
    static let defaultEndpoint = "https://stp-mobile-ci-test-backend-v7.stripedemos.com"
    static var playgroundSettings: CustomerSheetPlaygroundSettings?

    @IBOutlet weak var customerModeSelector: UISegmentedControl!

    @IBOutlet weak var pmModeSelector: UISegmentedControl!
    @IBOutlet weak var applePaySelector: UISegmentedControl!
    @IBOutlet weak var headerTextForSelectionScreenTextField: UITextField!

    @IBOutlet weak var loadButton: UIButton!

    @IBOutlet weak var selectPaymentMethodButton: UIButton!
    @IBOutlet weak var selectPaymentMethodImage: UIImageView!

    var customerSheet: CustomerSheet?
    var paymentOptionSelection: CustomerSheet.PaymentOptionSelection?

    enum CustomerMode: String, CaseIterable {
        case new
        case returning
    }

    enum PaymentMethodMode {
        case setupIntent
        case createAndAttach
    }

    var customerMode: CustomerMode {
        switch customerModeSelector.selectedSegmentIndex {
        case 0:
            return .new
        default:
            return .returning
        }
    }

    var paymentMethodMode: PaymentMethodMode {
        switch pmModeSelector.selectedSegmentIndex {
        case 0:
            return .setupIntent
        default:
            return .createAndAttach
        }
    }

    var backend: SavedPaymentMethodsBackend!

    var ephemeralKey: String?
    var customerId: String?
    var currentEndpoint: String = defaultEndpoint
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

    override func viewDidLoad() {
        super.viewDidLoad()
        loadButton.addTarget(self, action: #selector(load), for: .touchUpInside)
        selectPaymentMethodButton.isEnabled = false
        selectPaymentMethodButton.addTarget(
            self, action: #selector(didTapSelectPaymentMethodButton), for: .touchUpInside)

        if let settings = CustomerSheetTestPlayground.playgroundSettings {
            loadSettingsFrom(settings: settings)
        } else if let nsUserDefaultSettings = settingsFromDefaults() {
            loadSettingsFrom(settings: nsUserDefaultSettings)
            loadBackend()
        }
    }
    @objc
    func didTapSelectPaymentMethodButton() {
        customerSheet?.present(from: self, completion: { result in
            switch result {
            case .canceled:
                self.updateButtons()
                let alertController = self.makeAlertController()
                alertController.message = "Canceled"
                self.present(alertController, animated: true)
            case .selected(let paymentOptionSelection):
                self.paymentOptionSelection = paymentOptionSelection
                self.updateButtons()
                let alertController = self.makeAlertController()
                if let paymentOptionSelection = paymentOptionSelection {
                    alertController.message = "Success: \(paymentOptionSelection.displayData().label)"
                } else {
                    alertController.message = "Success: payment method unset"
                }
                self.present(alertController, animated: true)
            case .error(let error):
                print("something went wrong: \(error)")
            }
        })
    }

    func updateButtons() {
        // Update the payment method selection button
        if let paymentOption = self.paymentOptionSelection {
            self.selectPaymentMethodButton.setTitle(paymentOption.displayData().label, for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.label, for: .normal)
            self.selectPaymentMethodImage.image = paymentOption.displayData().image
        } else {
            self.selectPaymentMethodButton.setTitle("Select", for: .normal)
            self.selectPaymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            self.selectPaymentMethodImage.image = nil
        }
        self.selectPaymentMethodButton.setNeedsLayout()
    }

    @IBAction func didTapEndpointConfiguration(_ sender: Any) {
        // TODO
//        let endpointSelector = EndpointSelectorViewController(delegate: self,
//                                                              endpointSelectorEndpoint: Self.endpointSelectorEndpoint,
//                                                              currentCheckoutEndpoint: )
//        let navController = UINavigationController(rootViewController: endpointSelector)
//        self.navigationController?.present(navController, animated: true, completion: nil)
    }

    @IBAction func didTapResetConfig(_ sender: Any) {
        loadSettingsFrom(settings: CustomerSheetPlaygroundSettings.defaultValues())
    }

    @IBAction func appearanceButtonTapped(_ sender: Any) {
        if #available(iOS 14.0, *) {
            let vc = UIHostingController(rootView: AppearancePlaygroundView(appearance: appearance, doneAction: { updatedAppearance in
                self.appearance = updatedAppearance
                self.dismiss(animated: true, completion: nil)
            }))

            self.navigationController?.present(vc, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Unavailable", message: "Appearance playground is only available in iOS 14+.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func savedPaymentMethodSheetConfiguration(customerId: String, ephemeralKey: String) -> CustomerSheet.Configuration {
        var configuration = CustomerSheet.Configuration()
        configuration.appearance = appearance
        configuration.returnURL = "payments-example://stripe-redirect"
        configuration.headerTextForSelectionScreen = headerTextForSelectionScreenTextField.text

        return configuration
    }

    func customerAdapter(customerId: String, ephemeralKey: String) -> StripeCustomerAdapter {
        let customerAdapter: StripeCustomerAdapter
        switch paymentMethodMode {
        case .setupIntent:
            customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
                // This should be a block that fetches this from your server
                .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
            }, setupIntentClientSecretProvider: {
                return try await self.backend.createSetupIntent(customerId: customerId)
            })
        case .createAndAttach:
            customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
                // This should be a block that fetches this from your server
                .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
            })
        }
        return customerAdapter
    }

    func applePayEnabled() -> Bool {
        switch applePaySelector.selectedSegmentIndex {
        case 0:
            return true
        default:
            return false
        }
    }
}

// MARK: - Backend

extension CustomerSheetTestPlayground {
    @objc
    func load() {
        serializeSettingsToNSUserDefaults()
        loadBackend()
    }
    func loadBackend() {
        selectPaymentMethodButton.isEnabled = false
        customerSheet = nil
        paymentOptionSelection = nil

        let customerType = customerMode == .new ? "new" : "returning"
        self.backend = SavedPaymentMethodsBackend(endpoint: currentEndpoint)

//        TODO: Refactor this to make the ephemeral key and customerId fetching async
        self.backend.loadBackendCustomerEphemeralKey(customerType: customerType) { result in
            guard let json = result,
                  let ephemeralKey = json["customerEphemeralKeySecret"], !ephemeralKey.isEmpty,
                  let customerId = json["customerId"], !customerId.isEmpty,
                  let publishableKey = json["publishableKey"] else {
                return
            }
            self.ephemeralKey = ephemeralKey
            self.customerId = customerId
            StripeAPI.defaultPublishableKey = publishableKey

            Task {
                var configuration = self.savedPaymentMethodSheetConfiguration(customerId: customerId, ephemeralKey: ephemeralKey)
                configuration.applePayEnabled = self.applePayEnabled()
                let customerAdapter = self.customerAdapter(customerId: customerId, ephemeralKey: ephemeralKey)
                self.customerSheet = CustomerSheet(configuration: configuration, customer: customerAdapter)

                self.selectPaymentMethodButton.isEnabled = true

                let selection = try await customerAdapter.retrievePaymentOptionSelection()
                self.paymentOptionSelection = selection
                self.updateButtons()
            }
        }
    }
}

struct CustomerSheetPlaygroundSettings: Codable {
    static let nsUserDefaultsKey = "savedPaymentMethodPlaygroundSettings"

    let customerModeSelectorValue: Int
    let paymentMethodModeSelectorValue: Int
    let applePaySelectorSelectorValue: Int
    let selectingSavedCustomHeaderText: String?
    let savedPaymentMethodEndpoint: String?

    static func defaultValues() -> CustomerSheetPlaygroundSettings {
        return CustomerSheetPlaygroundSettings(
            customerModeSelectorValue: 0,
            paymentMethodModeSelectorValue: 0,
            applePaySelectorSelectorValue: 0,
            selectingSavedCustomHeaderText: nil,
            savedPaymentMethodEndpoint: CustomerSheetTestPlayground.defaultEndpoint
        )
    }
}

// MARK: - EndpointSelectorViewControllerDelegate
extension CustomerSheetTestPlayground: EndpointSelectorViewControllerDelegate {
    func selected(endpoint: String) {
        currentEndpoint = endpoint
        serializeSettingsToNSUserDefaults()
        loadBackend()
        self.navigationController?.dismiss(animated: true)

    }
    func cancelTapped() {
        self.navigationController?.dismiss(animated: true)
    }
}

// MARK: - Helpers

extension CustomerSheetTestPlayground {
    func serializeSettingsToNSUserDefaults() {
        let settings = CustomerSheetPlaygroundSettings(
            customerModeSelectorValue: customerModeSelector.selectedSegmentIndex,
            paymentMethodModeSelectorValue: pmModeSelector.selectedSegmentIndex,
            applePaySelectorSelectorValue: applePaySelector.selectedSegmentIndex,
            selectingSavedCustomHeaderText: headerTextForSelectionScreenTextField.text,
            savedPaymentMethodEndpoint: currentEndpoint
        )
        let data = try! JSONEncoder().encode(settings)
        UserDefaults.standard.set(data, forKey: CustomerSheetPlaygroundSettings.nsUserDefaultsKey)
    }

    func settingsFromDefaults() -> CustomerSheetPlaygroundSettings? {
        if let data = UserDefaults.standard.value(forKey: CustomerSheetPlaygroundSettings.nsUserDefaultsKey) as? Data {
            do {
                return try JSONDecoder().decode(CustomerSheetPlaygroundSettings.self, from: data)
            } catch {
                print("Unable to deserialize saved settings")
                UserDefaults.standard.removeObject(forKey: CustomerSheetPlaygroundSettings.nsUserDefaultsKey)
            }
        }
        return nil
    }

    func loadSettingsFrom(settings: CustomerSheetPlaygroundSettings) {
        customerModeSelector.selectedSegmentIndex = settings.customerModeSelectorValue
        pmModeSelector.selectedSegmentIndex = settings.paymentMethodModeSelectorValue
        applePaySelector.selectedSegmentIndex = settings.applePaySelectorSelectorValue
        headerTextForSelectionScreenTextField.text = settings.selectingSavedCustomHeaderText
        currentEndpoint = settings.savedPaymentMethodEndpoint ?? CustomerSheetTestPlayground.defaultEndpoint
    }
}

class SavedPaymentMethodsBackend {

    let endpoint: String
    public init(endpoint: String) {
        self.endpoint = endpoint
    }

    func loadBackendCustomerEphemeralKey(customerType: String, completion: @escaping ([String: String]?) -> Void) {

        let body = [ "customer_type": customerType
        ] as [String: Any]

        let url = URL(string: "\(endpoint)/customer_ephemeral_key")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, _, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data) else {
                print(error as Any)
                completion(nil)
                return
            }
            completion(json)
        }
        task.resume()
    }

    func createSetupIntent(customerId: String) async throws -> String {
        let body = [ "customer_id": customerId,
        ] as [String: Any]
        let url = URL(string: "\(endpoint)/create_setup_intent")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let (data, _) = try await session.data(for: urlRequest)
        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let secret = jsonResponse?["client_secret"] as? String else {
            throw NSError(domain: "test", code: 0, userInfo: nil) // Throw more specific error
        }
        return secret
    }
}
