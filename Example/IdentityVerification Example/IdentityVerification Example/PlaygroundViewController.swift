//
//  PlaygroundViewController.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 3/3/21.
//

// Note: Do not import Stripe using `@_spi(STP)` in production.
// This exposes internal functionality which may cause unexpected behavior if used directly.
@_spi(STP) import StripeIdentity
import UIKit

class PlaygroundViewController: UIViewController {

    // Constants
    let baseURL = "https://stripe-mobile-identity-verification-playground.glitch.me"
    let verifyEndpoint = "/create-verification-session"

    // Outlets
    @IBOutlet weak var verificationTypeSelector: UISegmentedControl!
    @IBOutlet weak var drivingLicenseSwitch: UISwitch!
    @IBOutlet weak var passportSwitch: UISwitch!
    @IBOutlet weak var idCardSwitch: UISwitch!
    @IBOutlet weak var requireIDNumberSwitch: UISwitch!
    @IBOutlet weak var requireLiveCaptureSwitch: UISwitch!
    @IBOutlet weak var requireSelfieSwitch: UISwitch!
    @IBOutlet weak var useNativeComponentsSwitch: UISwitch!
    @IBOutlet weak var documentOptionsContainerView: UIStackView!

    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    enum VerificationType: String, CaseIterable {
        case document
        case idNumber = "id_number"
    }

    enum DocumentAllowedType: String {
        case drivingLicense = "driving_license"
        case passport
        case idCard = "id_card"
    }

    /// VerificationType specified in the UI toggle
    var verificationType: VerificationType {
        let index = verificationTypeSelector.selectedSegmentIndex
        guard index >= 0 && index < VerificationType.allCases.count else {
            return .document
        }
        return VerificationType.allCases[index]
    }

    /// List of allowed document types based on UI toggles
    var documentAllowedTypes: [DocumentAllowedType] {
        var result: [DocumentAllowedType] = []
        if drivingLicenseSwitch.isOn {
            result.append(.drivingLicense)
        }
        if passportSwitch.isOn {
            result.append(.passport)
        }
        if idCardSwitch.isOn {
            result.append(.idCard)
        }
        return result
    }

    var verificationSheet: IdentityVerificationSheet?

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 14.3, *) {
            useNativeComponentsSwitch.isEnabled = true
        } else {
            useNativeComponentsSwitch.isEnabled = false
            useNativeComponentsSwitch.isOn = true
        }

        mockDocumentCameraForSimulator()

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

        // Forwarding VerificationSession options from the client to server to
        // for demo purposes. In production, these are typically set by the
        // server depending on the desired behavior.
        var requestDict: [String: Any] = [
            "type": verificationType.rawValue
        ]
        if verificationType == .document {
            let options: [String: Any] = [
                "document": [
                    "allowed_types": documentAllowedTypes.map { $0.rawValue },
                    "require_id_number": requireIDNumberSwitch.isOn,
                    "require_live_capture": requireLiveCaptureSwitch.isOn,
                    "require_matching_selfie": requireSelfieSwitch.isOn
                ]
            ]
            requestDict["options"] = options
        }
        let requestJson = try! JSONSerialization.data(withJSONObject: requestDict, options: [])

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.httpBody = requestJson

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
        let shouldUseNativeComponents = useNativeComponentsSwitch.isOn

        if shouldUseNativeComponents {
            setupVerificationSheetNativeUI(responseJson: responseJson)
        } else {
            setupVerificationSheetWebUI(responseJson: responseJson)
        }

        self.verificationSheet?.presentInternal(
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

    func setupVerificationSheetNativeUI(responseJson: [String: String]) {
        guard let verificationSessionId = responseJson["id"] else {
            assertionFailure("Did not receive a valid id.")
            return
        }
        guard let ephemeralKeySecret = responseJson["ephemeral_key_secret"] else {
            assertionFailure("Did not receive a valid ephemeral key secret.")
            return
        }
        self.verificationSheet = IdentityVerificationSheet(
            verificationSessionId: verificationSessionId,
            ephemeralKeySecret: ephemeralKeySecret
        )
        StripeAPI.defaultPublishableKey = responseJson["publishable_key"]
    }

    func setupVerificationSheetWebUI(responseJson: [String: String]) {
        guard let clientSecret = responseJson["client_secret"] else {
            assertionFailure("Did not receive a valid client secret.")
            return
        }
        self.verificationSheet = IdentityVerificationSheet(
            verificationSessionClientSecret: clientSecret
        )
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

    func mockDocumentCameraForSimulator() {
        #if targetEnvironment(simulator)
        if let frontImage = UIImage(named: "front_drivers_license.jpg"),
           let backImage = UIImage(named: "back_drivers_license.jpg") {
            IdentityVerificationSheet.simulatorDocumentCameraImages = [frontImage, backImage]
        }
        #endif
    }


    @IBAction func didChangeVerificationType(_ sender: Any) {
        switch verificationType {
        case .document:
            documentOptionsContainerView.isHidden = false
        case .idNumber:
            documentOptionsContainerView.isHidden = true
        }
    }
}

