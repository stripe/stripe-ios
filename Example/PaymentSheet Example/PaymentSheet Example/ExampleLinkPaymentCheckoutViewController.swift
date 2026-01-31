//
//  ExampleLinkPaymentCheckoutViewController.swift
//  PaymentSheet Example
//
//  Created by Vardges Avetisyan on 6/27/23.
//

import Foundation
@_spi(LinkOnly) import StripePaymentSheet
import UIKit

class ExampleLinkPaymentCheckoutViewController: UIViewController {
    @IBOutlet weak var buyButton: UIButton!
    @IBOutlet weak var paymentMethodButton: UIButton!
    @IBOutlet weak var paymentMethodImage: UIImageView!
    @IBOutlet weak var deferredSwitch: UISwitch!
    var linkPaymentController: LinkPaymentController!
    static let baseEndpoint = "https://stp-mobile-playground-backend-v7.stripedemos.com"
    var backendCheckoutUrl: String {
        "\(ExampleLinkPaymentCheckoutViewController.baseEndpoint)/checkout"
    }
    var confirmEndpoint: String {
        "\(ExampleLinkPaymentCheckoutViewController.baseEndpoint)/confirm_intent"
    }
    private var token = 0

    let billingDetails: PaymentSheet.BillingDetails = {
        var billingDetails = PaymentSheet.BillingDetails()
        // uncomment to test prefilled email
        // billingDetails.email = "email_\(UUID().uuidString)@email.com"
        // billingDetails.phone = "+15551232414567"
        return billingDetails
    }()

    private func loadBackend() {
        token += 1
        let thisToken = token

        Task {
            do {
                try await performLoadBackend(token: thisToken)
            } catch {
                print("Failed to load backend: \(error)")
            }
        }
    }

    private func performLoadBackend(token: Int) async throws {
        let (data, _) = try await makeRequest(with: backendCheckoutUrl, body: ["mode": "payment", "use_link": true])
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard
            let paymentIntentClientSecret = json?["intentClientSecret"] as? String,
            let publishableKey = json?["publishableKey"] as? String,
            self.token == token
        else {
            throw LinkPaymentError.invalidResponse
        }
        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey
        let returnURL = "payments-example://stripe-redirect"

        if self.deferredSwitch.isOn {
            let intentConfiguration = PaymentSheet
                .IntentConfiguration(
                    mode: .payment(amount: 100, currency: "usd"),
                    paymentMethodTypes: ["link"]) { [weak self] paymentMethod, shouldSavePaymentMethod in
                        guard let self = self else {
                            throw LinkPaymentError.viewControllerDeallocated
                        }
                        return try await self.handleDeferredIntent(clientSecret: paymentIntentClientSecret,
                                                                   paymentMethod: paymentMethod,
                                                                   shouldSavePaymentMethod: shouldSavePaymentMethod)
                    }

            self.linkPaymentController = LinkPaymentController(intentConfiguration: intentConfiguration, returnURL: returnURL, billingDetails: self.billingDetails)
        } else {
            self.linkPaymentController = LinkPaymentController(paymentIntentClientSecret: paymentIntentClientSecret, returnURL: returnURL, billingDetails: self.billingDetails)
        }

        self.updateButtons()
    }

    enum LinkPaymentError: Error {
        case viewControllerDeallocated
        case invalidResponse
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        buyButton.addTarget(self, action: #selector(didTapCheckoutButton), for: .touchUpInside)
        buyButton.isEnabled = false

        paymentMethodButton.addTarget(self, action: #selector(didTapPaymentMethodButton), for: .touchUpInside)
        paymentMethodButton.isEnabled = false

        loadBackend()
    }

    // MARK: - Button handlers

    @objc
    func didTapPaymentMethodButton() {
        buyButton.isEnabled = false
        linkPaymentController.present(from: self) { [weak self] result in
            switch result {
            case .success:
                self?.updateButtons()
            case .failure(let error):
                print(error as Any)
                self?.updateButtons()
            }
        }
    }

    @objc
    func didTapCheckoutButton() {
        linkPaymentController.confirm(from: self) { paymentResult in
            switch paymentResult {
            case .completed:
                self.displayAlert("Your order is confirmed!")
            case .canceled:
                print("Canceled!")
            case .failed(let error):
                print(error)
                self.displayAlert("Payment failed: \n\(error.localizedDescription)")
            }
        }
    }

    @IBAction func deferredSwitchDidChangeValue(_ sender: Any) {
        loadBackend()
    }

    // MARK: - Helper methods

    func updateButtons() {
        // MARK: Update the payment method and buy buttons
        if let paymentOption = linkPaymentController.paymentOption {
            paymentMethodButton.setTitle(paymentOption.label, for: .normal)
            paymentMethodButton.setTitleColor(.label, for: .normal)
            paymentMethodImage.image = paymentOption.image
            buyButton.isEnabled = true
        } else {
            paymentMethodButton.setTitle("Select", for: .normal)
            paymentMethodButton.setTitleColor(.systemBlue, for: .normal)
            paymentMethodImage.image = nil
            buyButton.isEnabled = false
            paymentMethodButton.isEnabled = true
        }
    }

    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
            alertController.dismiss(animated: true) {
                self.navigationController?.popViewController(animated: true)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }

    func handleDeferredIntent(clientSecret: String,
                              paymentMethod: STPPaymentMethod,
                              shouldSavePaymentMethod: Bool) async throws -> String {
        enum ConfirmHandlerError: Error, LocalizedError {
            case clientSecretNotFound
            case confirmError(String)

            public var errorDescription: String? {
                switch self {
                case .clientSecretNotFound:
                    return "Client secret not found in response from server."
                case .confirmError(let errorMessage):
                    return errorMessage
                }
            }
        }

        do {
            let (data, _) = try await makeRequest(
                with: confirmEndpoint,
                body: [
                    "mode": "payment",
                    "client_secret": clientSecret,
                    "payment_method_id": paymentMethod.stripeId,
                    "should_save_payment_method": shouldSavePaymentMethod,
                    "merchant_country_code": "US",
                    "return_url": "payments-example://stripe-redirect",
                ]
            )
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            guard let clientSecret = json?["client_secret"] as? String else {
                throw ConfirmHandlerError.clientSecretNotFound
            }

            return clientSecret
        } catch {
            // Check for 400 error with message
            if let urlError = error as? URLError,
               let data = urlError.userInfo[NSURLErrorFailingURLStringErrorKey] as? Data,
               let errorMessage = String(data: data, encoding: .utf8) {
                throw ConfirmHandlerError.confirmError(errorMessage)
            }
            throw error
        }
    }

    func makeRequest(with url: String, body: [String: Any]) async throws -> (Data, URLResponse) {
        let session = URLSession.shared
        let url = URL(string: url)!

        let json = try JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")

        return try await session.data(for: urlRequest)
    }
}
