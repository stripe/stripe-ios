//
//  PlaygroundViewController.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 3/3/21.
//

import StripeIdentity
import UIKit

class PlaygroundViewController: UIViewController {

    // Constants
    let baseURL = "https://stripe-mobile-identity-verification-playground.glitch.me"
    let verifyEndpoint = "/create-verification-session"

    // Outlets
    @IBOutlet private weak var nativeOrWebSelector: UISegmentedControl!
    @IBOutlet private weak var verificationTypeSelector: UISegmentedControl!
    @IBOutlet private weak var drivingLicenseSwitch: UISwitch!
    @IBOutlet private weak var passportSwitch: UISwitch!
    @IBOutlet private weak var idCardSwitch: UISwitch!
    @IBOutlet private weak var requireIDNumberSwitch: UISwitch!
    @IBOutlet private weak var requireAddressSwitch: UISwitch!
    @IBOutlet private weak var requireLiveCaptureSwitch: UISwitch!
    @IBOutlet private weak var requireSelfieSwitch: UISwitch!
    @IBOutlet private weak var documentOptionsContainerView: UIStackView!
    @IBOutlet private weak var nativeComponentsOptionsContainerView: UIStackView!

    @IBOutlet private weak var verifyButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    enum InvocationType: CaseIterable {
        case native
        case web
        case link
    }
    enum VerificationType: String, CaseIterable {
        case document = "document"
        case idNumber = "id_number"
        case address = "address"
    }

    enum DocumentAllowedType: String {
        case drivingLicense = "driving_license"
        case passport
        case idCard = "id_card"
    }

    /// Use native SDK or web redirect
    var invocationType: InvocationType {
        return InvocationType.allCases[nativeOrWebSelector.selectedSegmentIndex]
    }

    /// VerificationType specified in the UI toggle
    var verificationType: VerificationType {
        return VerificationType.allCases[verificationTypeSelector.selectedSegmentIndex]
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
            nativeOrWebSelector.isEnabled = true
        } else {
            nativeOrWebSelector.isEnabled = false
            nativeComponentsOptionsContainerView.isHidden = false
        }

        mockDocumentCameraForSimulator()

        activityIndicator.hidesWhenStopped = true
        verifyButton.addTarget(self, action: #selector(didTapVerifyButton), for: .touchUpInside)
    }

    @objc
    func didTapVerifyButton() {
        requestVerificationSession()
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
                    "require_matching_selfie": requireSelfieSwitch.isOn,
                    "require_address": requireAddressSwitch.isOn,
                ],
            ]
            requestDict["options"] = options
        }
        let requestJson = try! JSONSerialization.data(withJSONObject: requestDict, options: [])

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.httpBody = requestJson

        let task = session.dataTask(with: urlRequest) { [weak self] data, _, error in
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
        if invocationType == .link {
            displayAlert("Verification Link", responseJson["url"]!)
        } else {
            let shouldUseNativeComponents = invocationType == .native

            if !shouldUseNativeComponents,
                #available(iOS 14.3, *)
            {
                setupVerificationSheetWebUI(responseJson: responseJson)
            } else {
                setupVerificationSheetNativeUI(responseJson: responseJson)
            }

            let verificationSessionId = responseJson["id"]

            self.verificationSheet?.present(
                from: self,
                completion: { [weak self] result in
                    switch result {
                    case .flowCompleted:
                        self?.displayAlert("Completed!", verificationSessionId)
                    case .flowCanceled:
                        self?.displayAlert("Canceled!", verificationSessionId)
                    case .flowFailed(let error):
                        self?.displayAlert("Failed!", verificationSessionId)
                        print(error)
                    }
                }
            )
        }
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
            ephemeralKeySecret: ephemeralKeySecret,
            configuration: IdentityVerificationSheet.Configuration(
                brandLogo: UIImage(named: "BrandLogo")!
            )
        )
    }

    @available(iOS 14.3, *)
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

    func displayAlert(_ message: String, _ debugString: String?) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        if let debugString = debugString {
            alertController.addTextField { textField in
                textField.text = debugString
                textField.delegate = self

                // Prevent keyboard from displaying
                textField.inputView = UIView()
            }
        }
        let OKAction = UIAlertAction(title: "OK", style: .default) { (_) in
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
            let backImage = UIImage(named: "back_drivers_license.jpg")
        {
            IdentityVerificationSheet.simulatorDocumentCameraImages = [frontImage, backImage]
        }
        if let selfieImage = UIImage(named: "selfie.jpg") {
            IdentityVerificationSheet.simulatorSelfieCameraImages = [selfieImage]
        }
        #endif
    }

    @IBAction func didChangeVerificationType(_ sender: Any) {
        switch verificationType {
        case .document:
            documentOptionsContainerView.isHidden = false
        case .idNumber:
            documentOptionsContainerView.isHidden = true
        case .address:
            documentOptionsContainerView.isHidden = true
        }
    }

    @IBAction func didChangeNativeOrWeb(_ sender: Any) {
        switch invocationType {
        case .native:
            nativeComponentsOptionsContainerView.isHidden = false
        case .web:
            nativeComponentsOptionsContainerView.isHidden = true
        case .link:
            nativeComponentsOptionsContainerView.isHidden = true
        }
    }

    // MARK: – Customize Branding

    var originalTintColor: UIColor?
    let originalLabelFont = UILabel.appearance().font
    let originalLabelColor = UILabel.appearance().textColor
    let originalNavBarAppearance = UINavigationBar.appearance().standardAppearance

    @IBAction func didToggleCustomColorsFonts(_ uiSwitch: UISwitch) {
        if uiSwitch.isOn {
            enableCustomColorsFonts()
        } else {
            disableCustomColorsFonts()
        }
        applyUIAppearance()
    }

    func enableCustomColorsFonts() {
        originalTintColor = view.window?.tintColor

        let standardNavBarAppearance = UINavigationBarAppearance()
        UINavigationBar.appearance().standardAppearance = standardNavBarAppearance

        // Brand color can either be set using the window's tintColor
        // or by configuring AccentColor in the app's Assets file
        view.window?.tintColor = UIColor(named: "BrandColor")

        if let customFont = UIFont(name: "Futura", size: 17) {
            // Default font can be set on the UILabel's appearance
            UILabel.appearance().font = customFont

            // Navigation bar font can be set using `UINavigationBarAppearance`
            let barButtonAppearance = UIBarButtonItemAppearance(style: .plain)
            barButtonAppearance.normal.titleTextAttributes[.font] = customFont

            standardNavBarAppearance.buttonAppearance = barButtonAppearance
            standardNavBarAppearance.titleTextAttributes[.font] = customFont
        }

        // Default text color can be set on UILabel's appearance
        UILabel.appearance().textColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 0.80, green: 0.80, blue: 0.85, alpha: 1)

            default:
                return UIColor(red: 0.24, green: 0.26, blue: 0.34, alpha: 1)
            }
        }

        // Customize back button arrow
        standardNavBarAppearance.setBackIndicatorImage(
            UIImage(named: "BackArrow"),
            transitionMaskImage: UIImage(named: "BackArrow")
        )
    }

    func disableCustomColorsFonts() {
        view.window?.tintColor = originalTintColor
        UILabel.appearance().font = originalLabelFont
        UILabel.appearance().textColor = originalLabelColor
        UINavigationBar.appearance().standardAppearance = originalNavBarAppearance
        UINavigationBar.appearance().backIndicatorImage = nil
    }

    func applyUIAppearance() {
        // Changes to UIAppearance are only applied when the view is added to the window hierarchy
        UIApplication.shared.windows.forEach { window in
            window.subviews.forEach { view in
                view.removeFromSuperview()
                window.addSubview(view)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Reset custom colors if the view gets popped
        guard presentedViewController == nil else {
            return
        }
        disableCustomColorsFonts()
    }
}

// MARK: - Alert TextField Delegate

extension PlaygroundViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String)
        -> Bool
    {
        return false
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        textField.selectAll(nil)
    }
}
