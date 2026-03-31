//
//  PlaygroundViewController.swift
//  IdentityVerification Example
//
//  Created by Mel Ludowise on 3/3/21.
//

import StripeIdentity
@_spi(STP) import StripeUICore
import UIKit

class PlaygroundViewController: UIViewController {

    // Constants
    // View and fork the backend code here: https://codesandbox.io/p/devbox/dsx4vq
    let baseURL = "https://stripe-mobile-identity-verification-playground.stripedemos.com"
    let verifyEndpoint = "/verification-sessions"
    let reuseEndpoint = "/reuse-verification-session"

    // Outlets
    @IBOutlet private weak var nativeOrWebSelector: UISegmentedControl!
    @IBOutlet private weak var newOrReuseSelector: UISegmentedControl!
    @IBOutlet private weak var verificationTypeSelector: UISegmentedControl!
    @IBOutlet private weak var drivingLicenseSwitch: UISwitch!
    @IBOutlet private weak var passportSwitch: UISwitch!
    @IBOutlet private weak var idCardSwitch: UISwitch!
    @IBOutlet private weak var requireIDNumberSwitch: UISwitch!
    @IBOutlet private weak var requireAddressSwitch: UISwitch!
    @IBOutlet private weak var requireLiveCaptureSwitch: UISwitch!
    @IBOutlet private weak var requireSelfieSwitch: UISwitch!
    @IBOutlet private weak var verificationTypeContainerView: UIStackView!
    @IBOutlet private weak var documentOptionsContainerView: UIStackView!
    @IBOutlet private weak var nativeComponentsOptionsContainerView: UIStackView!
    @IBOutlet private weak var reuseVerificationIDContainerView: UIStackView!
    @IBOutlet private weak var reuseVerificationSessionIDInput: UITextField!

    @IBOutlet weak var phoneOptionsContainerView: UIStackView!
    @IBOutlet private weak var verifyButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var otpCheckSelector: UISegmentedControl!
    @IBOutlet weak var requirePhoneNumberSwitch: UISwitch!

    @IBOutlet weak var otpCheckContainerView: UIStackView!
    @IBOutlet weak var phoneOtpContainerView: UIStackView!

    @IBOutlet weak var fallbackToDocumentSwitch: UISwitch!
    private let phoneElement: PhoneNumberElement

    private let phoneView: UIView

    enum InvocationType: CaseIterable {
        case native
        case web
        case link
    }

    enum CreationMethod: CaseIterable {
        case new
        case reuse
    }

    enum VerificationType: String, CaseIterable {
        case document = "document"
        case idNumber = "id_number"
        case address = "address"
        case phone = "phone"
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

    /// Create new verification or reuse existing one
    var creationMethod: CreationMethod {
        return CreationMethod.allCases[newOrReuseSelector.selectedSegmentIndex]
    }

    /// VerificationType specified in the UI toggle
    var verificationType: VerificationType {
        return VerificationType.allCases[verificationTypeSelector.selectedSegmentIndex]
    }

    var shouldRequirePhoneOTPVerification: Bool {
        return otpCheckSelector.selectedSegmentIndex == 1
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

    required init?(coder aDecoder: NSCoder) {
        phoneElement = PhoneNumberElement()
        phoneView = phoneElement.view
        super.init(coder: aDecoder)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 14.3, *) {
            nativeOrWebSelector.isEnabled = true
        } else {
            nativeOrWebSelector.isEnabled = false
            nativeComponentsOptionsContainerView.isHidden = false
        }

        mockDocumentCameraForSimulator()

        phoneView.isHidden = true
        phoneOtpContainerView.addArrangedSubview(phoneView)

        activityIndicator.hidesWhenStopped = true
        verifyButton.addTarget(self, action: #selector(didTapVerifyButton), for: .touchUpInside)

        configureUpdatedParameterUI()
        didChangeNativeOrWeb(self)
        didChangeNewOrReuse(self)
    }

    @objc
    func didTapVerifyButton() {
        requestVerificationSession()
    }

    @IBAction func fallbackToDocumentValueChanged(_ uiSwitch: UISwitch) {
        documentOptionsContainerView.isHidden = !uiSwitch.isOn
    }

    @IBAction func requireOtpSwitchValueChanged(_ uiSwitch: UISwitch) {
        phoneView.isHidden = !uiSwitch.isOn
    }

    func requestVerificationSession() {
        // Disable the button while we make the request
        updateButtonState(isLoading: true)

        let session = URLSession.shared
        var url: URL
        var requestDict: [String: Any]

        if creationMethod == .reuse {
            url = URL(string: baseURL + reuseEndpoint)!

            requestDict = [
                "verification_session": reuseVerificationSessionIDInput.text ?? ""
            ]
        } else {
            // Make request to our verification endpoint
            url = URL(string: baseURL + verifyEndpoint)!

            // Forwarding VerificationSession options from the client to server to
            // for demo purposes. In production, these are typically set by the
            // server depending on the desired behavior.
            requestDict = [
                "type": verificationType.rawValue
            ]

            var options: [String: Any] = [:]
            var providedDetails: [String: Any] = [:]

            if requirePhoneNumberSwitch.isOn,
                let phoneNumber = phoneElement.phoneNumber?.string(as: .e164)
            {
                options["phone"] = [
                    "require_verification": true,
                ]
                providedDetails["phone"] = phoneNumber
            }

            switch verificationType {
            case .document:
                options["document"] = [
                    "allowed_types": documentAllowedTypes.map { $0.rawValue },
                    "require_id_number": requireIDNumberSwitch.isOn,
                    "require_live_capture": requireLiveCaptureSwitch.isOn,
                    "require_matching_selfie": requireSelfieSwitch.isOn,
                ]
            case .idNumber:
                break
            case .address:
                // no-op
                break
            case .phone:
                options["phone_otp"] = [
                    "require_verification": shouldRequirePhoneOTPVerification,
                ]
                if fallbackToDocumentSwitch.isOn {
                    options["document"] = [
                            "allowed_types": documentAllowedTypes.map { $0.rawValue },
                            "require_id_number": requireIDNumberSwitch.isOn,
                            "require_live_capture": requireLiveCaptureSwitch.isOn,
                            "require_matching_selfie": requireSelfieSwitch.isOn,
                        ]
                    options["phone_records"] = [
                        "fallback_type": "document",
                    ]
                }
            }

            if !providedDetails.isEmpty {
                requestDict["provided_details"] = providedDetails
            }
            requestDict["options"] = options

            do {
                let additionalParameters = try parsedAdditionalRequestParameters()
                if additionalParameters["verification_flow"] != nil,
                    additionalParameters["type"] == nil
                {
                    requestDict.removeValue(forKey: "type")
                }
                requestDict = mergeJSONObjects(
                    requestDict,
                    with: additionalParameters
                )
            } catch {
                updateButtonState(isLoading: false)
                displayAlert("Invalid additional params JSON", nil)
                return
            }
        }

        let requestJson: Data
        do {
            requestJson = try JSONSerialization.data(withJSONObject: requestDict, options: [])
        } catch {
            updateButtonState(isLoading: false)
            displayAlert("Unable to encode request parameters", nil)
            return
        }

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
            phoneOptionsContainerView.isHidden = true
            phoneOtpContainerView.isHidden = false
            phoneView.isHidden = !requirePhoneNumberSwitch.isOn
            fallbackToDocumentSwitch.isOn = false
            otpCheckContainerView.isHidden = true
            phoneElement.clearPhoneNumber()
        case .idNumber:
            documentOptionsContainerView.isHidden = true
            phoneOptionsContainerView.isHidden = true
            phoneOtpContainerView.isHidden = false
            phoneView.isHidden = !requirePhoneNumberSwitch.isOn
            fallbackToDocumentSwitch.isOn = false
            otpCheckContainerView.isHidden = true
            phoneElement.clearPhoneNumber()
        case .address:
            documentOptionsContainerView.isHidden = true
            phoneOptionsContainerView.isHidden = true
            phoneOtpContainerView.isHidden = true
            requirePhoneNumberSwitch.isOn = false
            phoneView.isHidden = true
            fallbackToDocumentSwitch.isOn = false
            otpCheckContainerView.isHidden = true
            phoneElement.clearPhoneNumber()
        case .phone:
            documentOptionsContainerView.isHidden = !fallbackToDocumentSwitch.isOn
            phoneOptionsContainerView.isHidden = false
            phoneOtpContainerView.isHidden = true
            requirePhoneNumberSwitch.isOn = false
            phoneView.isHidden = true
            otpCheckContainerView.isHidden = false
            phoneElement.clearPhoneNumber()
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

    // MARK: - New or Reuse Handlers
    @IBAction func didChangeNewOrReuse(_ sender: Any) {
        switch creationMethod {
        case .new:
            verificationTypeContainerView.isHidden = false
            configureRequestInputFieldForNewSession()
            didChangeVerificationType(sender)
        case .reuse:
            verificationTypeContainerView.isHidden = true
            documentOptionsContainerView.isHidden = true
            phoneOptionsContainerView.isHidden = true
            phoneOtpContainerView.isHidden = true
            requirePhoneNumberSwitch.isOn = false
            phoneView.isHidden = true
            fallbackToDocumentSwitch.isOn = false
            otpCheckContainerView.isHidden = true
            phoneElement.clearPhoneNumber()
            configureRequestInputFieldForSessionReuse()
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

private extension PlaygroundViewController {
    enum PlaygroundRequestBuilderError: Error {
        case additionalParametersMustBeJSONObject
    }

    var requestInputLabel: UILabel? {
        return reuseVerificationIDContainerView.arrangedSubviews.first as? UILabel
    }

    var duplicateDetectionLabel: UILabel? {
        return (requireAddressSwitch.superview as? UIStackView)?.arrangedSubviews.first as? UILabel
    }

    var phoneOTPLabel: UILabel? {
        return otpCheckContainerView.arrangedSubviews.first as? UILabel
    }

    func configureUpdatedParameterUI() {
        duplicateDetectionLabel?.text = "Enable Duplicate Detection"
        phoneOTPLabel?.text = "Require OTP Verification"

        while otpCheckSelector.numberOfSegments > 2 {
            otpCheckSelector.removeSegment(at: otpCheckSelector.numberOfSegments - 1, animated: false)
        }
        if otpCheckSelector.numberOfSegments < 2 {
            otpCheckSelector.insertSegment(withTitle: "Off", at: 0, animated: false)
            otpCheckSelector.insertSegment(withTitle: "On", at: 1, animated: false)
        } else {
            otpCheckSelector.setTitle("Off", forSegmentAt: 0)
            otpCheckSelector.setTitle("On", forSegmentAt: 1)
        }
        otpCheckSelector.selectedSegmentIndex = 1
    }

    func configureRequestInputFieldForNewSession() {
        reuseVerificationIDContainerView.isHidden = false
        requestInputLabel?.text = "Additional Params JSON (optional):"
        requestInputLabel?.numberOfLines = 0
        reuseVerificationSessionIDInput.text = nil
        reuseVerificationSessionIDInput.placeholder = "{\"client_reference_id\":\"user_123\",\"metadata\":{\"source\":\"ios_example\"}}"
    }

    func configureRequestInputFieldForSessionReuse() {
        reuseVerificationIDContainerView.isHidden = false
        requestInputLabel?.text = "VerificationSession ID:"
        requestInputLabel?.numberOfLines = 1
        reuseVerificationSessionIDInput.text = nil
        reuseVerificationSessionIDInput.placeholder = "vs_..."
    }

    func parsedAdditionalRequestParameters() throws -> [String: Any] {
        guard creationMethod == .new,
            let rawValue = reuseVerificationSessionIDInput.text?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawValue.isEmpty
        else {
            return [:]
        }

        let jsonObject = try JSONSerialization.jsonObject(with: Data(rawValue.utf8), options: [])
        guard let jsonDictionary = jsonObject as? [String: Any] else {
            throw PlaygroundRequestBuilderError.additionalParametersMustBeJSONObject
        }
        return jsonDictionary
    }

    func mergeJSONObjects(
        _ base: [String: Any],
        with overrides: [String: Any]
    ) -> [String: Any] {
        var result = base
        for (key, value) in overrides {
            if let overrideDictionary = value as? [String: Any],
                let baseDictionary = result[key] as? [String: Any]
            {
                result[key] = mergeJSONObjects(baseDictionary, with: overrideDictionary)
            } else {
                result[key] = value
            }
        }
        return result
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
