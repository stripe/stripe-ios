//
//  CollectBankAccountTokenViewController.swift
//  FinancialConnections Example
//
//  Created by Vardges Avetisyan on 11/12/21.
//

import UIKit
import StripeFinancialConnections

class CollectBankAccountTokenViewController: UIViewController {

    // MARK: - Constants

    let baseURL = "https://stripe-mobile-connections-example.glitch.me"
    let financialConnectionsEndpoint = "/create_session_for_token"

    // MARK: - IBOutlets

    @IBOutlet weak var collectBankAccountTokenButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties

    private var financialConnectionsSheet: FinancialConnectionsSheet?

    // MARK: - IBActions

    @IBAction func didTapCollectBankAccount(_ sender: Any) {
        requestFinancialConnectionsSession()
    }
    // MARK: - Helpers

    private func requestFinancialConnectionsSession() {
        // Disable the button while we make the request
        updateButtonState(isLoading: true)

        // Make request to our verification endpoint
        let session = URLSession.shared
        let url = URL(string: baseURL + financialConnectionsEndpoint)!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                guard
                    error == nil,
                    let data = data,
                    let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
                else {
                    // Re-enable button
                    self.updateButtonState(isLoading: false)
                    print(error as Any)
                    return
                }

                self.startFinancialConnections(responseJson: responseJson)
             }
        }
        task.resume()
    }

    private func startFinancialConnections(responseJson: [String: String]) {
        guard let clientSecret = responseJson["client_secret"] else {
            assertionFailure("Did not receive a valid client secret.")
            return
        }
        guard let publishableKey = responseJson["publishable_key"]  else {
            assertionFailure("Did not receive a valid publishable key.")
            return
        }

        // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
        STPAPIClient.shared.publishableKey = publishableKey

        financialConnectionsSheet = FinancialConnectionsSheet(financialConnectionsSessionClientSecret: clientSecret)
        financialConnectionsSheet?.presentForToken(
            from: self,
            completion: { [weak self] result in
                switch result {
                case .completed(result: let result):
                    guard let token = result.token else {
                        self?.displayAlert("Completed, but no token was returned")
                        return
                    }
                    let info = "\(token.bankAccount.bankName ?? "") ....\(token.bankAccount.last4)"
                    self?.displayAlert("Completed with account \(info) and token \(token.id) ")
                case .canceled:
                    self?.displayAlert("Canceled!")
                case .failed(let error):
                    self?.displayAlert("Failed!")
                    print(error)
                }
            })
        // Re-enable button
        updateButtonState(isLoading: false)
    }

    private func updateButtonState(isLoading: Bool) {
        // Re-enable button
        collectBankAccountTokenButton.isEnabled = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            alertController.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}
