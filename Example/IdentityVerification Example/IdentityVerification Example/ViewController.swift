//
//  ViewController.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 3/3/21.
//

import UIKit
import StripeIdentity

class ViewController: UIViewController {

    // Constants
    let baseURL = "https://stripe-mobile-identity-verification-example.glitch.me"
    let verifyEndpoint = "/create-verification-session"

    // Outlets
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var buildVersionLabel: UILabel!

    var verificationSheet: IdentityVerificationSheet?

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.hidesWhenStopped = true
        verifyButton.addTarget(self, action: #selector(didTapVerifyButton), for: .touchUpInside)

        setupBuildVersionLabel()
    }

    func setupBuildVersionLabel() {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let version = infoDictionary["CFBundleShortVersionString"] as? String,
              let build = infoDictionary["CFBundleVersion"] as? String else {
            return
        }
        buildVersionLabel.text = "v\(version) build \(build)"
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

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")

        let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async { [weak self] in
                // Re-enable button
                self?.updateButtonState(isLoading: false)

                guard
                    error == nil,
                    let data = data,
                    let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
                else {
                    print(error as Any)
                    return
                }

                self?.startVerificationFlow(responseJson: responseJson)
             }
        }
        task.resume()
    }

    func startVerificationFlow(responseJson: [String: String]) {
        guard let clientSecret = responseJson["client_secret"] else {
            assertionFailure("Did not receive a valid client secret.")
            return
        }
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

