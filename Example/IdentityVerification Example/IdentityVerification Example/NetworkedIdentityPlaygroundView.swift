//
//  NetworkedIdentityPlaygroundView.swift
//  IdentityVerification Example
//

import StripeCore
@_spi(STP) import StripeIdentity
@_spi(STP) import StripePaymentSheet
import UIKit

/// Networked Identity playground controls. The example acts as the "outside" host: it signs in to
/// Link itself and hands the resulting consumer session to Identity, like crypto onramp would.
final class NetworkedIdentityPlaygroundView: UIStackView {
    /// Link-enabled test merchant from the CryptoOnramp example, so the playground works out of the box.
    private static let onrampTestPublishableKey =
        "pk_test_51K9W3OHMaDsveWq0oLP0ZjldetyfHIqyJcz27k2BpMGHxu9v9Cei2tofzoHncPyk3A49jMkFEgTOBQyAMTUffRLa00xzzARtZO"

    private let merchantKeyField = NetworkedIdentityPlaygroundView.makeField("Merchant publishable key")
    private let linkEmailField = NetworkedIdentityPlaygroundView.makeField("User email (provided_details.email)")
    private let codeField = NetworkedIdentityPlaygroundView.makeField("Verification code (000000 in test mode)")
    private let phoneField = NetworkedIdentityPlaygroundView.makeField("Phone number, E.164 (+39…)")
    private let countryField = NetworkedIdentityPlaygroundView.makeField("Country code")
    private let seedSwitch = UISwitch()
    private let sendCodeButton = UIButton(type: .system)
    private let verifyButton = UIButton(type: .system)
    private let createAccountButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let statusLabel = UILabel()
    private lazy var buttonRow = makeButtonRow()

    private var controller: LinkController?
    private var handoff: IdentityVerificationSheet.Configuration.LinkSessionHandoff?

    /// The options to pass to `IdentityVerificationSheet.Configuration.networkedIdentity`.
    var networkedIdentityOptions: IdentityVerificationSheet.Configuration.NetworkedIdentityOptions? {
        let publishableKey = trimmed(merchantKeyField)
        guard !publishableKey.isEmpty || handoff != nil else {
            return nil
        }
        return .init(
            linkSessionHandoff: handoff,
            debugMerchantPublishableKey: publishableKey.isEmpty ? nil : publishableKey,
            // The user email stands in for provided_details.email, which the example can't set on the session.
            debugProvidedEmail: trimmed(linkEmailField).nilIfEmpty,
            debugRoute: nil,
            debugSeedSavedDocuments: seedSwitch.isOn
        )
    }

    init() {
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        axis = .vertical
        spacing = 8
        seedSwitch.isOn = true
        merchantKeyField.text = Self.onrampTestPublishableKey
        linkEmailField.text = "federico.frappi@gmail.com"
        linkEmailField.keyboardType = .emailAddress
        codeField.keyboardType = .numberPad
        phoneField.keyboardType = .phonePad
        countryField.text = "IT"
        countryField.autocapitalizationType = .allCharacters
        setAwaitingCode(false)
        setNeedsSignUp(false)
        clearButton.isHidden = true
        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .footnote)

        sendCodeButton.setTitle("Send code", for: .normal)
        sendCodeButton.addTarget(self, action: #selector(didTapSendCode), for: .touchUpInside)
        verifyButton.setTitle("Verify", for: .normal)
        verifyButton.addTarget(self, action: #selector(didTapVerify), for: .touchUpInside)
        createAccountButton.setTitle("Create account", for: .normal)
        createAccountButton.addTarget(self, action: #selector(didTapCreateAccount), for: .touchUpInside)
        clearButton.setTitle("Clear handoff", for: .normal)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)

        addArrangedSubview(makeTitleLabel())
        addArrangedSubview(merchantKeyField)
        addArrangedSubview(makeSeedRow())
        addArrangedSubview(linkEmailField)
        addArrangedSubview(codeField)
        addArrangedSubview(phoneField)
        addArrangedSubview(countryField)
        addArrangedSubview(buttonRow)
        addArrangedSubview(statusLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Link sign-in

extension NetworkedIdentityPlaygroundView {
    @objc private func didTapSendCode() {
        let publishableKey = trimmed(merchantKeyField)
        let email = trimmed(linkEmailField)
        guard !publishableKey.isEmpty, !email.isEmpty else {
            statusLabel.text = "Enter a merchant publishable key and a user email first."
            return
        }
        setNeedsSignUp(false)
        statusLabel.text = "Signing in to Link…"
        makeController(publishableKey: publishableKey) { [weak self] controller in
            controller.lookupConsumer(with: email) { [weak self] result in
                switch result {
                case .success(let isConsumer) where isConsumer:
                    self?.startVerificationOrCapture()
                case .success:
                    self?.setNeedsSignUp(true)
                    self?.statusLabel.text = "No Link account for \(email). Enter a phone number to create one."
                case .failure(let error):
                    self?.show(error)
                }
            }
        }
    }

    @objc private func didTapVerify() {
        let code = trimmed(codeField)
        guard !code.isEmpty, let controller else {
            statusLabel.text = "Enter the code from the SMS."
            return
        }
        statusLabel.text = "Confirming code…"
        controller.confirmVerification(code: code) { [weak self] result in
            switch result {
            case .success:
                self?.captureHandoff()
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    @objc private func didTapCreateAccount() {
        let phone = trimmed(phoneField)
        let country = trimmed(countryField).uppercased()
        guard !phone.isEmpty, !country.isEmpty, let controller else {
            statusLabel.text = "Enter a phone number and a country code."
            return
        }
        statusLabel.text = "Creating Link account…"
        controller.registerLinkUser(
            fullName: nil,
            phone: phone,
            country: country,
            consentAction: .implied_v0_0
        ) { [weak self] result in
            switch result {
            case .success:
                self?.setNeedsSignUp(false)
                self?.captureHandoff()
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    @objc private func didTapClear() {
        handoff = nil
        clearButton.isHidden = true
        statusLabel.text = "Handoff cleared."
    }

    private func setAwaitingCode(_ awaiting: Bool) {
        codeField.isHidden = !awaiting
        verifyButton.isHidden = !awaiting
    }

    private func setNeedsSignUp(_ needed: Bool) {
        phoneField.isHidden = !needed
        countryField.isHidden = !needed
        createAccountButton.isHidden = !needed
    }

    private func makeController(publishableKey: String, completion: @escaping (LinkController) -> Void) {
        if let controller {
            completion(controller)
            return
        }
        LinkController.create(
            apiClient: STPAPIClient(publishableKey: publishableKey),
            mode: .setup,
            // #TODO - Networked Identity [NI-Contract]: use `.identity` once "ios_identity_product" is deployed.
            requestSurface: .cryptoOnramp
        ) { [weak self] result in
            switch result {
            case .success(let controller):
                self?.controller = controller
                completion(controller)
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    private func startVerificationOrCapture() {
        guard let controller else {
            return
        }
        if controller.linkAccount?.sessionState == .verified {
            captureHandoff()
            return
        }
        controller.startVerification(isResendingSmsCode: false) { [weak self] result in
            switch result {
            case .success:
                self?.setAwaitingCode(true)
                self?.statusLabel.text = "Enter the code sent by SMS (000000 in test mode)."
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    private func captureHandoff() {
        guard let account = controller?.linkAccount,
              let secret = account.consumerSessionClientSecret, !secret.isEmpty,
              let publishableKey = account.consumerPublishableKey, !publishableKey.isEmpty
        else {
            statusLabel.text = "Link returned no consumer session."
            return
        }
        handoff = .init(
            email: account.email,
            consumerSessionClientSecret: secret,
            consumerPublishableKey: publishableKey
        )
        setAwaitingCode(false)
        codeField.text = nil
        clearButton.isHidden = false
        statusLabel.text = "Link session ready for \(account.email)."
    }

    private func show(_ error: Error) {
        statusLabel.text = "Link error: \(error.localizedDescription)"
    }
}

// MARK: - Keyboard

extension NetworkedIdentityPlaygroundView {
    /// The playground screen doesn't scroll and this panel sits at its bottom, so the screen is shifted up
    /// while the keyboard would cover the fields and buttons being used.
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let screen = owningViewController?.view
        else {
            return
        }
        let editing = [merchantKeyField, linkEmailField, codeField, phoneField, countryField].contains { $0.isFirstResponder }
        let previous = screen.transform
        screen.transform = .identity
        let overlap = buttonRow.convert(buttonRow.bounds, to: nil).maxY + 8 - keyboardFrame.minY
        screen.transform = previous
        UIView.animate(withDuration: 0.25) {
            screen.transform = editing && overlap > 0 ? CGAffineTransform(translationX: 0, y: -overlap) : .identity
        }
    }

    private var owningViewController: UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}

// MARK: - Subviews

extension NetworkedIdentityPlaygroundView {
    private static func makeField(_ placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        // Number and phone pads have no return key, so every field gets a Done button to close the keyboard.
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(systemItem: .done, primaryAction: UIAction { [weak field] _ in
                field?.resignFirstResponder()
            }),
        ]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
        return field
    }

    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = "Networked Identity (Link)"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func makeSeedRow() -> UIStackView {
        let label = UILabel()
        label.text = "Seed saved documents"
        let row = UIStackView(arrangedSubviews: [seedSwitch, label])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    private func makeButtonRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [sendCodeButton, verifyButton, createAccountButton, clearButton, UIView()])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .center
        return row
    }

    private func trimmed(_ field: UITextField) -> String {
        (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String {
    fileprivate var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
