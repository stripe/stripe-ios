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
/// It only signs in to existing Link accounts; Identity's own Link sheet covers sign-up.
final class NetworkedIdentityPlaygroundView: UIStackView {
    /// Link-enabled test merchant from the CryptoOnramp example, so the playground works out of the box.
    private static let onrampTestPublishableKey =
        "pk_test_51K9W3OHMaDsveWq0oLP0ZjldetyfHIqyJcz27k2BpMGHxu9v9Cei2tofzoHncPyk3A49jMkFEgTOBQyAMTUffRLa00xzzARtZO"

    private let merchantKeyField = NetworkedIdentityPlaygroundView.makeField("Merchant publishable key")
    private let linkEmailField = NetworkedIdentityPlaygroundView.makeField("User email (lookup_email)")
    private let signInButton = UIButton(type: .system)
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
            // Stands in for lookup_email until the playground's sessions return it.
            debugProvidedEmail: trimmed(linkEmailField).nilIfEmpty,
            // The playground supplies eligibility until its test sessions return the v8 fields.
            debugRoute: "reuse"
        )
    }

    init() {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 8
        merchantKeyField.text = Self.onrampTestPublishableKey
        linkEmailField.keyboardType = .emailAddress
        clearButton.isHidden = true
        statusLabel.numberOfLines = 0
        statusLabel.font = .preferredFont(forTextStyle: .footnote)

        signInButton.setTitle("Sign in to Link", for: .normal)
        signInButton.addTarget(self, action: #selector(didTapSignIn), for: .touchUpInside)
        clearButton.setTitle("Clear handoff", for: .normal)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)

        addArrangedSubview(makeTitleLabel())
        addArrangedSubview(merchantKeyField)
        addArrangedSubview(linkEmailField)
        addArrangedSubview(buttonRow)
        addArrangedSubview(statusLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Link sign-in

extension NetworkedIdentityPlaygroundView {
    @objc private func didTapSignIn() {
        let publishableKey = trimmed(merchantKeyField)
        let email = trimmed(linkEmailField)
        guard !publishableKey.isEmpty, !email.isEmpty else {
            statusLabel.text = "Enter a merchant publishable key and a user email first."
            return
        }
        statusLabel.text = "Signing in to Link…"
        makeController(publishableKey: publishableKey) { [weak self] controller in
            controller.lookupConsumer(with: email) { [weak self] result in
                switch result {
                case .success(let isConsumer) where isConsumer:
                    self?.verifyOrCaptureHandoff()
                case .success:
                    self?.statusLabel.text = "No Link account for \(email). Create one in Identity's Link sheet first."
                case .failure(let error):
                    self?.show(error)
                }
            }
        }
    }

    @objc private func didTapClear() {
        handoff = nil
        clearButton.isHidden = true
        statusLabel.text = "Handoff cleared."
    }

    private func makeController(publishableKey: String, completion: @escaping (LinkController) -> Void) {
        if let controller {
            completion(controller)
            return
        }
        LinkController.create(
            apiClient: STPAPIClient(publishableKey: publishableKey),
            mode: .setup,
            // Stands in for crypto onramp, so it uses onramp's request surface.
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

    private func verifyOrCaptureHandoff() {
        guard let controller else {
            return
        }
        if controller.linkAccount?.sessionState == .verified {
            captureHandoff()
            return
        }
        guard let host = hostViewController else {
            statusLabel.text = "No view controller to present Link's verification from."
            return
        }
        controller.presentForVerification(from: host) { [weak self] result in
            switch result {
            case .success(.completed):
                self?.captureHandoff()
            case .success(.canceled):
                self?.statusLabel.text = "Link sign-in canceled."
            case .failure(let error):
                self?.show(error)
            }
        }
    }

    private func captureHandoff() {
        guard let account = controller?.linkAccount,
              let linkSessionKey = account.linkSessionKey, !linkSessionKey.isEmpty
        else {
            statusLabel.text = "Link returned no consumer session."
            return
        }
        handoff = .init(email: account.email, linkSessionKey: linkSessionKey)
        clearButton.isHidden = false
        statusLabel.text = "Link session ready for \(account.email)."
    }

    private func show(_ error: Error) {
        statusLabel.text = "Link error: \(error.localizedDescription)"
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
        // Return doesn't close the keyboard in this form, so every field gets a Done button.
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

    private func makeButtonRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [signInButton, clearButton, UIView()])
        row.axis = .horizontal
        row.spacing = 16
        row.alignment = .center
        return row
    }

    private func trimmed(_ field: UITextField) -> String {
        (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hostViewController: UIViewController? {
        sequence(first: self as UIResponder, next: \.next).first { $0 is UIViewController } as? UIViewController
    }
}

extension String {
    fileprivate var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
