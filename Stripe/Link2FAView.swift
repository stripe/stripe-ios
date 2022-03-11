//
//  Link2FAView.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// :nodoc:
protocol Link2FAViewDelegate: AnyObject {
    func link2FAViewDidCancel(_ view: Link2FAView)
    func link2FAViewResendCode(_ view: Link2FAView)
    func link2FAViewLogout(_ view: Link2FAView)
    func link2FAView(_ view: Link2FAView, didEnterCode code: String)
}

/// For internal SDK use only
@objc(STP_Internal_Link2FAView)
final class Link2FAView: UIView {
    struct Constants {
        static let edgeMargin: CGFloat = 20
    }

    enum Mode {
        case modal
        case inlineLogin
        case embedded
    }

    weak var delegate: Link2FAViewDelegate?

    private let mode: Mode

    let linkAccount: PaymentSheetLinkAccountInfoProtocol

    var sendingCode: Bool = false {
        didSet {
            resendCodeButton.isLoading = sendingCode
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
        label.text = mode.headingText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var bodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = mode.bodyFont
        label.textColor = CompatibleColor.secondaryLabel
        label.text = mode.bodyText(redactedPhoneNumber: linkAccount.redactedPhoneNumber ?? "")
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private(set) lazy var codeField: OneTimeCodeTextField = {
        let codeField = OneTimeCodeTextField(numberOfDigits: 6)
        codeField.addTarget(self, action: #selector(oneTimeCodeFieldChanged(_:)), for: .valueChanged)
        return codeField
    }()

    private lazy var resendCodeButton: Button = {
        // TODO(ramont): Localize
        let button = Button(configuration: .linkBordered(), title: "Resend code")
        button.addTarget(self, action: #selector(resendCodeTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var logoutView: LogoutView = {
        let logoutView = LogoutView(linkAccount: linkAccount)
        logoutView.button.addTarget(self, action: #selector(didTapOnLogout(_:)), for: .touchUpInside)
        return logoutView
    }()

    required init(mode: Mode, linkAccount: PaymentSheetLinkAccountInfoProtocol) {
        self.mode = mode
        self.linkAccount = linkAccount
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func oneTimeCodeFieldChanged(_ sender: OneTimeCodeTextField) {
        if sender.isComplete {
            delegate?.link2FAView(self, didEnterCode: sender.value)
        }
    }

    @objc
    func didSelectCancel() {
        delegate?.link2FAViewDidCancel(self)
    }

    @objc
    func didTapOnLogout(_ sender: UIButton) {
        delegate?.link2FAViewLogout(self)
    }

    @objc
    func resendCodeTapped(_ sender: UIButton) {
        delegate?.link2FAViewResendCode(self)
    }
}

private extension Link2FAView {

    var arrangedSubViews: [UIView] {
        switch mode {
        case .modal, .inlineLogin:
            return [
                header,
                headingLabel,
                bodyLabel,
                codeField,
                resendCodeButton
            ]
        case .embedded:
            return [
                headingLabel,
                bodyLabel,
                codeField,
                logoutView,
                resendCodeButton
            ]
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
        stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: codeField)

        addSubview(stackView)

        var constraints: [NSLayoutConstraint] = [
            // Stack view
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            // OTC field
            codeField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            codeField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ]

        if mode.requiresModalPresentation {
            constraints.append(contentsOf: [
                // Header
                header.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            ])
        }

        NSLayoutConstraint.activate(constraints)
        backgroundColor = CompatibleColor.systemBackground
    }
}

extension Link2FAView.Mode {

    var requiresModalPresentation: Bool {
        switch self {
        case .modal, .inlineLogin:
            return true
        case .embedded:
            return false
        }
    }

    var headingText: String {
        switch self {
        case .modal:
            // TODO(ramont): Localize
            return "Use your saved info to check out faster"
        case .inlineLogin:
            // TODO(ramont): Localize
            return "Sign in to your Link account"
        case .embedded:
            // TODO(ramont): Localize
            return "Enter your verification code"
        }
    }

    var bodyFont: UIFont {
        switch self {
        case .modal, .inlineLogin:
            return LinkUI.font(forTextStyle: .detail)
        case .embedded:
            return LinkUI.font(forTextStyle: .body)
        }
    }

    func bodyText(redactedPhoneNumber: String) -> String {
        // TODO(ramont): Localize and format number
        return String(
            format: "Enter the code sent to %@ to use Link to pay by default.",
            redactedPhoneNumber
        )
    }

}
