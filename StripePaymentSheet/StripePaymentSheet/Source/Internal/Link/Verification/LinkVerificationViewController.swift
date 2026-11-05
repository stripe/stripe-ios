//
//  LinkVerificationViewController.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 3/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// The OTP screen shared by SMS, email, and both auth presentations.
final class LinkVerificationViewController: UIViewController {
    let verificationView: LinkVerificationView
    private let coordinator: LinkAuthFlowCoordinator
    private var inputRevision = -1
    private var invalidCodeRevision = 0
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
        verificationView.codeField.addAction(UIAction { [weak self] _ in self?.codeFieldChanged() }, for: .valueChanged)
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
        if invalidCodeRevision != coordinator.invalidCodeRevision {
            invalidCodeRevision = coordinator.invalidCodeRevision
            if coordinator.canSubmitCode {
                // Clears the field once the animation finishes.
                verificationView.codeField.performInvalidCodeAnimation()
            } else {
                verificationView.codeField.value = ""
            }
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
        verificationView.configureActions(
            title: title,
            enabled: hasAlternatives ? !isLoading : coordinator.canResend,
            loading: isLoading
        )
        menuButton.isHidden = true
        verificationView.actionsButton.isAccessibilityElement = true
        if #available(iOS 14.0, *), hasAlternatives, !isLoading {
            menuButton.isHidden = false
            menuButton.isEnabled = true
            menuButton.accessibilityLabel = title
            verificationView.actionsButton.isAccessibilityElement = false
            menuButton.showsMenuAsPrimaryAction = true
            let menu = UIMenu(
                children: menuItems.map { item in
                    UIAction(
                        title: item.title,
                        image: UIImage(systemName: item.systemImageName),
                        attributes: item.isEnabled ? [] : [.disabled]
                    ) {
                        _ in item.handler()
                    }
                }
            )
            menuButton.menu = menu
            menuButton.contextMenuInteraction?.updateVisibleMenu { _ in menu }
        }
    }

    func focusCode() {
        guard coordinator.canSubmitCode else { return }
        verificationView.codeField.becomeFirstResponder()
    }

    private func codeFieldChanged() {
        coordinator.codeDidChange()
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

    private struct MenuItem {
        let title: String
        let systemImageName: String
        let isEnabled: Bool
        let handler: () -> Void
    }

    private var menuItems: [MenuItem] {
        coordinator.actions.map { action in
            switch action {
            case .resend:
                return MenuItem(
                    title: resendTitle,
                    systemImageName: "arrow.clockwise",
                    isEnabled: coordinator.canResend
                ) { [weak self] in
                    self?.coordinator.resend()
                }
            case .email:
                let title = STPLocalizedString(
                    "Email code",
                    "Link authentication action to receive an email verification code."
                )
                return MenuItem(title: title, systemImageName: "envelope", isEnabled: true) { [weak self] in
                    self?.coordinator.sendToEmail()
                }
            }
        }
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
        for item in menuItems {
            let action = UIAlertAction(title: item.title, style: .default) { _ in item.handler() }
            action.isEnabled = item.isEnabled
            menu.addAction(action)
        }
        menu.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel))
        menu.popoverPresentationController?.sourceView = view.actionsButton
        menu.popoverPresentationController?.sourceRect = view.actionsButton.bounds
        present(menu, animated: true)
    }
}
