//
//  LinkVerificationView.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 3/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// :nodoc:
protocol LinkVerificationViewDelegate: AnyObject {
    func verificationViewDidCancel(_ view: LinkVerificationView)
    func verificationViewResendCode(_ view: LinkVerificationView)
    func verificationViewLogout(_ view: LinkVerificationView)
    func verificationView(_ view: LinkVerificationView, didEnterCode code: String)
}

/// For internal SDK use only
@objc(STP_Internal_LinkVerificationView)
final class LinkVerificationView: UIView {
    struct Constants {
        static let edgeMargin: CGFloat = 20
    }

    enum Mode {
        case modal
        case inlineLogin
        case embedded
    }

    weak var delegate: LinkVerificationViewDelegate?

    private let mode: Mode

    let linkAccount: PaymentSheetLinkAccountInfoProtocol

    private let appearance: LinkAppearance?
    private let allowLogoutInDialog: Bool
    private let consentViewModel: LinkConsentViewModel?

    var sendingCode: Bool = false {
        didSet {
            resendCodeButton.isLoading = sendingCode
        }
    }

    var errorMessage: String? {
        didSet {
            errorLabel.text = errorMessage
            errorLabel.setHiddenIfNecessary(errorMessage == nil)
        }
    }

    private lazy var header: Header = {
        let header = Header()
        header.closeButton.addTarget(self, action: #selector(didSelectCancel), for: .touchUpInside)
        return header
    }()

    private lazy var headingLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = LinkUI.font(forTextStyle: .title)
        label.textColor = .linkTextPrimary
        label.text = mode.headingText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = mode.bodyFont
        label.textColor = .linkTextSecondary
        label.text = mode.bodyText(redactedPhoneNumber: linkAccount.redactedPhoneNumber ?? "")
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private(set) lazy var codeField: OneTimeCodeTextField = {
        let codeField = OneTimeCodeTextField(
            configuration: .init(
                numberOfDigits: 6,
                enableDigitGrouping: false,
                font: LinkUI.font(forTextStyle: .title).bold,
                itemCornerRadius: LinkUI.oneTimeCodeTextFieldCornerRadius,
                itemHeight: 56,
                itemFocusRingThickness: LinkUI.borderWidth,
                itemFocusBackgroundColor: LinkUI.appearance.colors.background
            ),
            theme: LinkUI.appearance.asElementsTheme
        )
        codeField.tintColor = appearance?.colors?.selectedBorder ?? LinkUI.appearance.colors.selectedComponentBorder
        codeField.addTarget(self, action: #selector(oneTimeCodeFieldChanged(_:)), for: .valueChanged)
        return codeField
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .detail)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var codeFieldContainer: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [codeField, errorLabel])
        stackView.axis = .vertical
        stackView.spacing = LinkUI.smallContentSpacing
        return stackView
    }()

    private lazy var resendCodeButton: Button = {
        let button = Button(configuration: .linkPlain(foregroundColor: appearance?.colors?.primary ?? .linkTextBrand), title: String.Localized.resend_code)
        button.configuration.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        button.addTarget(self, action: #selector(resendCodeTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var logoutView: LogoutView = {
        let logoutView = LogoutView(linkAccount: linkAccount)
        logoutView.button.addTarget(self, action: #selector(didTapOnLogout(_:)), for: .touchUpInside)
        return logoutView
    }()

    private lazy var consentDisclaimerLabel: UILabel? = {
        guard case .inline(let inlineConsent) = consentViewModel else {
            return nil
        }

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = LinkUI.font(forTextStyle: .caption)
        label.textColor = .linkTextTertiary
        label.text = inlineConsent.disclaimer
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    required init(
        mode: Mode,
        linkAccount: PaymentSheetLinkAccountInfoProtocol,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool,
        consentViewModel: LinkConsentViewModel? = nil
    ) {
        self.mode = mode
        self.linkAccount = linkAccount
        self.appearance = appearance
        self.allowLogoutInDialog = allowLogoutInDialog
        self.consentViewModel = consentViewModel
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func oneTimeCodeFieldChanged(_ sender: OneTimeCodeTextField) {
        // Clear error message when the field changes.
        errorMessage = nil

        if sender.isComplete {
            delegate?.verificationView(self, didEnterCode: sender.value)
        }
    }

    @objc
    func didSelectCancel() {
        delegate?.verificationViewDidCancel(self)
    }

    @objc
    func didTapOnLogout(_ sender: UIButton) {
        delegate?.verificationViewLogout(self)
    }

    @objc
    func resendCodeTapped(_ sender: UIButton) {
        delegate?.verificationViewResendCode(self)
    }
}

private extension LinkVerificationView {

    var arrangedSubViews: [UIView] {
        switch mode {
        case .modal, .inlineLogin:
            var views = [
                header,
                headingLabel,
                bodyLabel,
                codeFieldContainer,
                resendCodeButton,
            ]

            if let consentDisclaimerLabel = consentDisclaimerLabel {
                views.append(consentDisclaimerLabel)
            }

            if allowLogoutInDialog {
                views.append(logoutView)
            }

            return views
        case .embedded:
            var views = [
                headingLabel,
                bodyLabel,
                codeFieldContainer,
                resendCodeButton,
            ]

            if let consentDisclaimerLabel = consentDisclaimerLabel {
                views.append(consentDisclaimerLabel)
            }

            views.append(logoutView)
            return views
        }
    }

    func setupUI() {
        directionalLayoutMargins = .insets(amount: Constants.edgeMargin)

        let stackView = UIStackView(arrangedSubviews: arrangedSubViews)
        stackView.spacing = LinkUI.smallContentSpacing
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Spacing
        stackView.setCustomSpacing(Constants.edgeMargin, after: header)
        stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: bodyLabel)
        stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: codeFieldContainer)
        stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: resendCodeButton)

        // Add spacing after consent disclaimer if present
        if let consentDisclaimerLabel = consentDisclaimerLabel {
            stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: consentDisclaimerLabel)
        }

        addSubview(stackView)

        var constraints: [NSLayoutConstraint] = [
            // Stack view
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            // OTC field
            codeFieldContainer.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            codeFieldContainer.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ]

        if mode.requiresModalPresentation {
            constraints.append(contentsOf: [
                // Header
                header.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            ])
        }

        NSLayoutConstraint.activate(constraints)
        backgroundColor = .systemBackground
    }
}

extension LinkVerificationView.Mode {

    var requiresModalPresentation: Bool {
        switch self {
        case .modal, .inlineLogin:
            return true
        case .embedded:
            return false
        }
    }

    var headingText: String {
        return String.Localized.confirm_its_you
    }

    var bodyFont: UIFont {
        switch self {
        case .modal:
            return LinkUI.font(forTextStyle: .detail)
        case .inlineLogin, .embedded:
            return LinkUI.font(forTextStyle: .body)
        }
    }

    func bodyText(redactedPhoneNumber: String) -> String {
        let format = String.Localized.enter_code_sent_to
        return String(format: format, redactedPhoneNumber)
    }

}
