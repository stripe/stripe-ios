//
//  VerificationExplanationViewController.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/17/21.
//

import UIKit
import StripeCardScan

/**
This view controller emulates a developer's integration experience. 
 1. Make a request to the simulated merchant server to retrieve the CIV intent details
 2. Initialize a `CardImageVerificationSheet`
 3. Present the sheet and run the scanning flow
 */
private struct civIntentDetails {
    let id: String
    let clientSecret: String
}

class VerificationExplanationViewController: UIViewController {
    // MARK: Views
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonActivityIndicator: UIActivityIndicatorView!

    // MARK: Instance Properties
    private var cardVerificationSheet: CardImageVerificationSheet?
    private let continueButtonTitleString = "Continue"

    @IBAction func didTapContinueButton(_ sender: Any) {
        startVerificationFlow()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        fetchCIVIntentDetails()
    }
}

// MARK: UI Logic
private extension VerificationExplanationViewController {
    func setUpViews() {
        continueButton.layer.cornerRadius = 10.0
        continueButton.setTitle("", for: .disabled)
    }

    func updateButtonState(isLoading: Bool) {
        continueButton.isEnabled = !isLoading
        if isLoading {
            continueButtonActivityIndicator.startAnimating()
        } else {
            continueButtonActivityIndicator.stopAnimating()
        }
    }

    func displayAlert(_ message: String) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}

private extension VerificationExplanationViewController {
    func fetchCIVIntentDetails() {
        /// Disable button until card image verification sheet is set
        updateButtonState(isLoading: true)

        /// Make request to our verification endpoint
        let url = URL(string: "https://stripe-card-scan-civ-example-app.glitch.me/checkout")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            DispatchQueue.main.async { [weak self] in
                guard
                    error == nil,
                    let data = data,
                    let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
                else {
                    print("Could not get response")
                    return
                }

                /// Extract card image verification intent id and client secret
                guard
                    let id = responseJson["id"],
                    let clientSecret = responseJson["client_secret"]
                else {
                    print("Could not parse response")
                    return
                }

                /// Initialize the card image verification sheet with the id and client secret
                self?.cardVerificationSheet = CardImageVerificationSheet(cardImageVerificationIntentId: id, cardImageVerificationIntentSecret: clientSecret)
                self?.updateButtonState(isLoading: false)
             }
        }.resume()
    }

    func startVerificationFlow() {
        self.cardVerificationSheet?.present(from: self) { result in
            switch result {
            case .completed(let card):
                let last4 = String(card.pan.suffix(4))
                self.displayAlert("Completed scan with \(last4)")
            case .canceled(let reason):
                self.displayAlert("Canceled for the following reason: \(reason)")
            case .failed(_):
                self.displayAlert("Failed")
            @unknown default:
                return
            }
        }
    }
}
