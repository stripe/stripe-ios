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
        case inline
    }

    weak var delegate: Link2FAViewDelegate?

    private let mode: Mode
    private let redactedPhoneNumber: String

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
        label.text = mode.bodyText(redactedPhoneNumber: redactedPhoneNumber)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private(set) lazy var codeField: OneTimeCodeTextField = {
        let codeField = OneTimeCodeTextField(numberOfDigits: 6)
        codeField.addTarget(self, action: #selector(oneTimeCodeFieldChanged(_:)), for: .valueChanged)
        return codeField
    }()

    private lazy var resendCodeButton: UIButton = {
        let button = UIButton(type: .system)
        // TODO(ramont): Localize
        button.setTitle("Resend code", for: .normal)
        button.titleLabel?.font = LinkUI.font(forTextStyle: .bodyEmphasized)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.addTarget(self, action: #selector(resendCodeTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var separator: SeparatorLabel = {
        // TODO(ramont): Localize
        let separator = SeparatorLabel(text: "Or")
        separator.adjustsFontForContentSizeCategory = true
        return separator
    }()

    private lazy var cancelButton: Button = {
        // TODO(ramont): Localize
        let button = Button(configuration: .linkSecondary(), title: "Pay another way")
        button.addTarget(self, action: #selector(didSelectCancel), for: .touchUpInside)
        button.adjustsFontForContentSizeCategory = true
        return button
    }()

    required init(mode: Mode, redactedPhoneNumber: String) {
        self.mode = mode
        self.redactedPhoneNumber = redactedPhoneNumber
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
    func resendCodeTapped(_ sender: UIButton) {
        delegate?.link2FAViewResendCode(self)
    }
}

private extension Link2FAView {

    var arrangedSubViews: [UIView] {
        switch mode {
        case .modal:
            return [
                header,
                headingLabel,
                bodyLabel,
                resendCodeButton,
                codeField,
                separator,
                cancelButton
            ]
        case .inline:
            return [
                headingLabel,
                bodyLabel,
                codeField,
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
        stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: codeField)

        switch mode {
        case .modal:
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: resendCodeButton)
            stackView.setCustomSpacing(LinkUI.largeContentSpacing, after: separator)
        case .inline:
            stackView.setCustomSpacing(LinkUI.extraLargeContentSpacing, after: bodyLabel)
        }

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

        if mode == .modal {
            constraints.append(contentsOf: [
                // Header
                header.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                header.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

                // Separator
                separator.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                separator.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

                // Button
                cancelButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
                cancelButton.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
            ])
        }

        NSLayoutConstraint.activate(constraints)
        backgroundColor = CompatibleColor.systemBackground
    }
}

private extension Link2FAView.Mode {

    var headingText: String {
        switch self {
        case .modal:
            // TODO(ramont): Localize
            return "Check out faster with Link"
        case .inline:
            // TODO(ramont): Localize
            return "Enter your verification code"
        }
    }

    var bodyFont: UIFont {
        switch self {
        case .modal:
            return LinkUI.font(forTextStyle: .detail)
        case .inline:
            return LinkUI.font(forTextStyle: .body)
        }
    }

    func bodyText(redactedPhoneNumber: String) -> String {
        switch self {
        case .modal:
            // TODO(ramont): Localize and format number
            return String(
                format: "It looks like you’ve saved info to Link before. Enter the code sent to %@.",
                redactedPhoneNumber
            )
        case .inline:
            // TODO(ramont): Localize and format number
            return String(
                format: "Enter the code sent to %@ to securely use your saved information.",
                redactedPhoneNumber
            )
        }
    }

}
