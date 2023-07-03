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
    let backendCheckoutUrl = "https://abundant-elderly-universe.glitch.me/checkout"  // An example backend endpoint
    let confirmEndpoint = "https://abundant-elderly-universe.glitch.me/confirm_intent"
    private var token = 0

    private func loadBackend() {
        token += 1
        let thisToken = token
        makeRequest(with: backendCheckoutUrl, body: ["mode": "payment"]) {
            [weak self] (data, _, _) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: [])
                    as? [String: Any],
                  let paymentIntentClientSecret = json["intentClientSecret"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let self = self,
                  self.token == thisToken
            else {
                // Handle error
                return
            }
            // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
            STPAPIClient.shared.publishableKey = publishableKey
            let returnURL = "payments-example://stripe-redirect"
            DispatchQueue.main.async {
                if self.deferredSwitch.isOn {
                    let intentConfiguration = PaymentSheet
                        .IntentConfiguration(
                            mode: .payment(amount: 100, currency: "usd"),
                            paymentMethodTypes: ["link"]) { [weak self] _, _, intentCreationCallback in
                                self?.handleDeferredIntent(intentCreationCallback: intentCreationCallback)
                            }

                    self.linkPaymentController = LinkPaymentController(intentConfiguration: intentConfiguration, returnURL: returnURL)
                } else {
                    self.linkPaymentController = LinkPaymentController(paymentIntentClientSecret: paymentIntentClientSecret, returnURL: returnURL)
                }

                self.updateButtons()
            }
        }
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
            paymentMethodButton.setTitleColor(.black, for: .normal)
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

    func handleDeferredIntent(intentCreationCallback: @escaping ((Result<String, Error>) -> Void) ) {
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
        makeRequest(with: confirmEndpoint, body: ["mode": "payment"], completionHandler: { data, response, error in
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
}
