//
//  LinkVerificationViewController.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 3/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// The OTP screen shared by SMS, email, and both auth presentations.
final class LinkVerificationViewController: UIViewController {
    typealias VerificationResult = LinkVerificationResult

    let verificationView: LinkVerificationView
    private let coordinator: LinkAuthFlowCoordinator
    private var inputRevision = -1
    private let menuButton = UIButton(type: .system)

    init(
        mode: LinkVerificationView.Mode,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        appearance: LinkAppearance?,
        allowLogoutInDialog: Bool,
        consentViewModel: LinkConsentViewModel?,
        coordinator: LinkAuthFlowCoordinator
    ) {
        self.coordinator = coordinator
        verificationView = LinkVerificationView(
            mode: mode,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel,
            showsHeader: false
        )
        super.init(nibName: nil, bundle: nil)
        verificationView.delegate = self
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = verificationView
        view.backgroundColor = .clear
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        verificationView.addSubview(menuButton)
        NSLayoutConstraint.activate([
            menuButton.topAnchor.constraint(equalTo: verificationView.actionsButton.topAnchor),
            menuButton.bottomAnchor.constraint(equalTo: verificationView.actionsButton.bottomAnchor),
            menuButton.leadingAnchor.constraint(equalTo: verificationView.actionsButton.leadingAnchor),
            menuButton.trailingAnchor.constraint(equalTo: verificationView.actionsButton.trailingAnchor),
        ])
    }

    func render() {
        loadViewIfNeeded()
        if inputRevision != coordinator.inputRevision {
            inputRevision = coordinator.inputRevision
            verificationView.codeField.value = ""
        }
        verificationView.recipient = coordinator.recipient
        verificationView.errorMessage = coordinator.errorMessage
        verificationView.setCodeEntryEnabled(coordinator.canSubmitCode)
        let hasAlternatives = coordinator.actions.count > 1
        let isLoading = coordinator.isLoadingOTP
        let title = hasAlternatives ? STPLocalizedString(
            "More options",
            "Button opening Link authentication actions."
        ) : resendTitle
        verificationView.configureActions(title: title, enabled: hasAlternatives ? !isLoading : coordinator.canResend, loading: isLoading)
        menuButton.isHidden = true
        verificationView.actionsButton.isAccessibilityElement = true
        if #available(iOS 14.0, *), hasAlternatives, !isLoading {
            menuButton.isHidden = false
            menuButton.isEnabled = true
            menuButton.accessibilityLabel = title
            verificationView.actionsButton.isAccessibilityElement = false
            menuButton.showsMenuAsPrimaryAction = true
            let menu = UIMenu(children: [
                UIAction(title: resendTitle, image: UIImage(systemName: "arrow.clockwise"), attributes: coordinator.canResend ? [] : [.disabled]) { [weak self] _ in self?.coordinator.resend() },
                UIAction(title: emailActionTitle, image: UIImage(systemName: "envelope")) { [weak self] _ in self?.coordinator.sendToEmail() },
            ])
            menuButton.menu = menu
            menuButton.contextMenuInteraction?.updateVisibleMenu { _ in menu }
        }
    }

    func focusCode() {
        guard coordinator.canSubmitCode else { return }
        verificationView.codeField.becomeFirstResponder()
    }

    private var resendTitle: String {
        let seconds = coordinator.resendSecondsRemaining
        guard seconds > 0 else { return String.Localized.resend_code }
        return String(
            format: STPLocalizedString(
                "Resend code in %d seconds",
                "Link OTP resend cooldown, in seconds."
            ),
            seconds
        )
    }

    private var emailActionTitle: String {
        STPLocalizedString(
            "Email code",
            "Link authentication action to receive an email verification code."
        )
    }
}

extension LinkVerificationViewController: LinkVerificationViewDelegate {
    func verificationViewDidCancel(_ view: LinkVerificationView) { coordinator.cancel() }
    func verificationViewLogout(_ view: LinkVerificationView) { coordinator.cancel(switchAccount: true) }
    func verificationView(_ view: LinkVerificationView, didEnterCode code: String) { coordinator.confirm(code: code) }
    func verificationViewResendCode(_ view: LinkVerificationView) {
        guard coordinator.actions.count > 1 else {
            coordinator.resend()
            return
        }
        // iOS 13 doesn't support opening a UIButton menu on its primary action.
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let resend = UIAlertAction(
            title: resendTitle,
            style: .default
        ) { [weak self] _ in
            self?.coordinator.resend()
        }
        resend.isEnabled = coordinator.canResend
        menu.addAction(resend)

        menu.addAction(
            UIAlertAction(
                title: emailActionTitle,
                style: .default
            ) { [weak self] _ in
                self?.coordinator.sendToEmail()
            }
        )
        menu.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel))
        menu.popoverPresentationController?.sourceView = view.actionsButton
        menu.popoverPresentationController?.sourceRect = view.actionsButton.bounds
        present(menu, animated: true)
    }
}
