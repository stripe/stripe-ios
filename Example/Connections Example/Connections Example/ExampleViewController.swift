//
//  ViewController.swift
//  Connections Example
//
//  Created by Vardges Avetisyan on 11/12/21.
//

import UIKit
import StripeConnections

class ExampleViewController: UIViewController {

    // MARK: - Constants
    
    let baseURL = "https://desert-instinctive-eoraptor.glitch.me"
    let connectionsEndpoint = "/create_link_account_session"

    // MARK: - IBOutlets
    
    @IBOutlet weak var connectAccountButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    fileprivate var connectionsSheet: ConnectionsSheet?
    
    // MARK: - IBActions
    
    @IBAction func didTapConnectAccount(_ sender: Any) {
        requestConnectionsSession()
    }
    
    // MARK: - Helpers
    
    fileprivate func requestConnectionsSession() {
        // Disable the button while we make the request
        updateButtonState(isLoading: true)

        // Make request to our verification endpoint
        let session = URLSession.shared
        let url = URL(string: baseURL + connectionsEndpoint)!

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

                self.startConnections(responseJson: responseJson)
             }
        }
        task.resume()
    }
 
    fileprivate func startConnections(responseJson: [String: String]) {
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

        connectionsSheet = ConnectionsSheet(linkAccountSessionClientSecret: clientSecret)
        connectionsSheet?.present(
            from: self,
            completion: { [weak self] result in
                switch result {
                case .completed(linkedAccounts: let linkedAccounts):
                    let messages = linkedAccounts.map { $0.last4! }
                    self?.displayAlert("Completed with \(messages.joined(separator: ", ")) accounts")
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
    
    fileprivate func updateButtonState(isLoading: Bool) {
        // Re-enable button
        connectAccountButton.isEnabled = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    fileprivate func displayAlert(_ message: String) {
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

