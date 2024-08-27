//
//  TestModeAutofillBannerView.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-06-20.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class TestModeAutofillBannerView: UIView {

    enum Context {
        case account
        case otp

        var buttonLabel: String {
            switch self {
            case .account:
                STPLocalizedString(
                    "Use test account",
                    "Label for a button shown to a user who is in test mode, which will give them the option to autofill mock account credentials."
                )
            case .otp:
                STPLocalizedString(
                    "Use test code",
                    "Label for a button shown to a user who is in test mode, which will give them the option to autofill a mock one time passcode."
                )
            }
        }
    }

    private let context: Context
    private let theme: FinancialConnectionsTheme
    private let didTapAutofill: () -> Void

    // MARK: - Subviews

    private lazy var messageLabel: UILabel = {
        // Create icon as a text attachement.
        let icon = Image.info
            .makeImage(template: true)
            .withTintColor(.attention300)
        let textAttachment = NSTextAttachment(image: icon)

        textAttachment.bounds = CGRect(
            x: 0,
            y: -3,
            width: icon.size.width,
            height: icon.size.height
        )

        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(attachment: textAttachment))
        // Add a spacer between the icon and the label in the form of a space.
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(NSAttributedString(string: STPLocalizedString(
            "You're in test mode.",
            "Message shown to a user who is in test mode, which will give them the option to autofill mock credentials."
        )))

        let label = UILabel()
        label.attributedText = attributedString
        label.font = FinancialConnectionsFont.body(.small).uiFont
        label.textColor = .textDefault
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var autofillDataButton: UIButton = {
        let button = UIButton()
        button.setTitle(context.buttonLabel, for: .normal)
        button.setTitleColor(theme.textActionColor, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.titleLabel?.font = FinancialConnectionsFont.label(.mediumEmphasized).uiFont
        button.addTarget(self, action: #selector(autofillTapped), for: .touchUpInside)
        button.accessibilityIdentifier = "test_mode_autofill_button"
        return button
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: - Init and setup

    init(context: Context, theme: FinancialConnectionsTheme, didTapAutofill: @escaping () -> Void) {
        self.context = context
        self.theme = theme
        self.didTapAutofill = didTapAutofill
        super.init(frame: .zero)
        setupLayout()
    }

    private func setupLayout() {
        backgroundColor = .attention50
        layer.cornerRadius = 12
        clipsToBounds = true

        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(autofillDataButton)

        messageLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        autofillDataButton.setContentHuggingPriority(.required, for: .horizontal)
        autofillDataButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: 12),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -24),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func autofillTapped() {
        didTapAutofill()
    }
}

#if DEBUG

import SwiftUI

private struct TestModeAutofillBannerViewRepresentable: UIViewRepresentable {
    let bannerContext: TestModeAutofillBannerView.Context
    let theme: FinancialConnectionsTheme

    func makeUIView(context: Context) -> TestModeAutofillBannerView {
        TestModeAutofillBannerView(context: bannerContext, theme: theme, didTapAutofill: {})
    }

    func updateUIView(_ uiView: TestModeAutofillBannerView, context: Context) {}
}

struct TestModeAutofillBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TestModeAutofillBannerViewRepresentable(bannerContext: .account, theme: .light)
                .frame(height: 38)

            TestModeAutofillBannerViewRepresentable(bannerContext: .otp, theme: .light)
                .frame(height: 38)

            TestModeAutofillBannerViewRepresentable(bannerContext: .otp, theme: .linkLight)
                .frame(height: 38)
        }
        .padding()
    }
}

#endif
