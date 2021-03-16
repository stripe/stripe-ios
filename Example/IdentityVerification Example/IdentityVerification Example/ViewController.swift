//
//  ViewController.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 3/3/21.
//

import UIKit
import Stripe

let redirectFromVerificationNotification = Notification.Name(rawValue: "redirectFromVerificationNotification")

class ViewController: UIViewController {

    // Constants
    let baseURL = "https://stripe-mobile-identity-verification-example.glitch.me"
    let verifyEndpoint = "/create-verification-session"

    // Outlets
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var verificationSheet: IdentityVerificationSheet?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Observe the notification posted by SceneDelegate's URL handler
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveRedirectFromVerificationNotification), name: redirectFromVerificationNotification, object: nil)

        activityIndicator.hidesWhenStopped = true
        verifyButton.addTarget(self, action: #selector(didTapVerifyButton), for: .touchUpInside)
    }

    @objc
    func didTapVerifyButton() {
        requestVerificationSession()
    }

    @objc
    func didReceiveRedirectFromVerificationNotification() {
        displayAlert("Finished verification in browser!")
    }

    func requestVerificationSession() {
        // Disable the button while we make the request
        updateButtonState(isLoading: true)

        // Make request to our verification endpoint
        let session = URLSession.shared
        let url = URL(string: baseURL + verifyEndpoint)!

        // IdentityVerificationSheet is only supported on iOS 14.3
        // Tell the server to fallback to using a URL redirect for older versions
        var supportsVerificationSheet = false
        if #available(iOS 14.3, *) {
            supportsVerificationSheet = true
        }
        let requestBody = try! JSONEncoder().encode([
            "client_supports_verification_sheet": supportsVerificationSheet,
        ])

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.httpBody = requestBody

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard
                error == nil,
                let data = data,
                let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
            else {
                print(error as Any)
                DispatchQueue.main.async { [weak self] in
                    self?.updateButtonState(isLoading: false)
                }
                return
            }

            DispatchQueue.main.async { [weak self] in
                // Re-enable button
                self?.updateButtonState(isLoading: false)

                self?.startVerificationFlow(responseJson: responseJson)
             }
        }
        task.resume()
    }

    func startVerificationFlow(responseJson: [String: String]) {
        if #available(iOS 14.3, *),
           let clientSecret = responseJson["client_secret"] {
            self.verificationSheet = IdentityVerificationSheet(verificationSessionClientSecret: clientSecret)
            self.verificationSheet?.present(
                from: self,
                completion: { [weak self] result in
                switch result {
                case .flowCompleted:
                    self?.displayAlert("Completed!")
                case .flowCanceled:
                    self?.displayAlert("Canceled!")
                case .flowFailed(let error):
                    self?.displayAlert("Failed!")
                    print(error)
                }
            })
        } else if let verificationURLString = responseJson["url"],
              let verificationURL = URL(string: verificationURLString) {
            UIApplication.shared.open(verificationURL)
        } else {
            assertionFailure("Did not receive a valid url or client secret.")
        }
    }

    func updateButtonState(isLoading: Bool) {
        // Re-enable button
        verifyButton.isEnabled = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    func displayAlert(_ message: String) {
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

