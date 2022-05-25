//
//  VerificationExplanationViewController.swift
//  CardImageVerification Example
//
//  Created by Jaime Park on 11/17/21.
//

import UIKit
@_spi(STP) import StripeCardScan

///TODO(jaimepark) Internal structs. Find better place 
private struct CIVIntentDetails {
    let id: String
    let clientSecret: String
}

struct ExpectedCardViewModel {
    let iin: String
    let last4: String
}

/**
This view controller emulates a developer's integration experience.
 1. Make a request to the simulated merchant server to retrieve the CIV intent details
 2. Initialize a `CardImageVerificationSheet`
 3. Present the sheet and run the scanning flow
 */
class VerificationExplanationViewController: UIViewController {
    // MARK: Views
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var continueButtonActivityIndicator: UIActivityIndicatorView!

    // MARK: Instance Properties
    private var cardVerificationSheet: CardImageVerificationSheet?
    private var civIntentDetails: CIVIntentDetails?

    private let continueButtonTitleString = "Continue"
    var expectedCardViewModel: ExpectedCardViewModel?

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

    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler:  { _ in
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        })
        alertController.addAction(OKAction)
        present(alertController, animated: true, completion: nil)
    }
}

private extension VerificationExplanationViewController {
    func fetchCIVIntentDetails() {
        /// Disable button until card image verification sheet is set
        updateButtonState(isLoading: true)

        let requestJson = [
            "expected_card[iin]": expectedCardViewModel?.iin ?? "424242",
            "expected_card[last4]": expectedCardViewModel?.last4 ?? "4242"
        ]
        
        /// Make request to our verification endpoint
        APIClient.jsonRequest(
            url: URLHelper.cardSet.verifyURL,
            requestJson: requestJson,
            httpMethod: "POST"
        ) { [weak self] responseData in

            guard let data = responseData,
                  let responseJson = try? JSONDecoder().decode([String: String].self, from: data)
            else {
                print("Could not fetch civ intent")
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

            /// Make sure to set your publishable key to make Stripe API requests
            STPAPIClient.shared.publishableKey = "pk_test_51JSpW7CBqurEnDFxtKkJdafmVOuV2yQWbdKye2SCPpnKP7ClIuUNTAOFfgDd3rCjB6X3PVpGNPGt65L7uWYbo9LD00mlkvI2Ih"

            var configuration = CardImageVerificationSheet.Configuration()
            configuration.strictModeFrames = .high

            /// Initialize the card image verification sheet with the id and client secret
            self?.cardVerificationSheet = CardImageVerificationSheet(
                cardImageVerificationIntentId: id,
                cardImageVerificationIntentSecret: clientSecret,
                configuration: configuration
            )
            self?.civIntentDetails = CIVIntentDetails(id: id, clientSecret: clientSecret)
            self?.updateButtonState(isLoading: false)
        }
    }

    func startVerificationFlow() {
        self.cardVerificationSheet?.present(from: self) { result in
            switch result {
            case .completed(let card):
                let last4 = String(card.pan.suffix(4))
                /// Make `/verify` request after flow is complete to get verification results
                APIClient.jsonRequest(url: URLHelper.verify.verifyURL, requestJson: ["civ_id": self.civIntentDetails!.id], httpMethod: "POST") {
                    [weak self] result in

                    let serverResponse: String = {
                        var responseString = "Verification flow has completed but could not retrieve verification results"
                        if let result = result {
                            responseString = "\(String(data: result, encoding: .utf8)!)"
                        }

                        return responseString
                    }()
                    /// Display the scanned card's last 4 and `/verify` response
                    self?.displayAlert(title: "Verification Completed: •••• \(last4)",
                                       message: serverResponse)
                }
            case .canceled(let reason):
                self.displayAlert(
                    title: "Verification Canceled",
                    message: "Canceled for the following reason: \(reason)"
                )
            case .failed(let error):
                self.displayAlert(
                    title: "Verification Failed",
                    message: "Failed with error: \(error.localizedDescription)"
                )
            }
        }
    }
}
