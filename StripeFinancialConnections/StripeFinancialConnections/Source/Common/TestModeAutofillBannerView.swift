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
            y: -2,
            width: icon.size.width,
            height: icon.size.height
        )
        
        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(attachment: textAttachment))
        attributedString.append(NSAttributedString(string: STPLocalizedString(
            " You're in test mode.",
            "Message shown to a user who is in test mode, which will give them the option to autofill mock credentials. There is intentionally a leading space here to provide a bit of spacing between the text and the icon."
        )))
        
        let label = UILabel()
        label.attributedText = attributedString
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .textDefault
        return label
    }()
    
    private lazy var autofillDataButton: UIButton = {
        let button = UIButton()
        let title = context.buttonLabel
        button.setTitle(title, for: .normal)
        button.setTitleColor(.textActionPrimary, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.titleLabel?.font = .preferredFont(forTextStyle: .body, weight: .semibold)
        button.addTarget(self, action: #selector(autofillTapped), for: .touchUpInside)
        return button
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: - Init

    init(context: Context, didTapAutofill: @escaping () -> Void) {
        self.context = context
        self.didTapAutofill = didTapAutofill
        super.init(frame: .zero)
        
        backgroundColor = .attention50
        layer.cornerRadius = 12
        clipsToBounds = true
        
        autofillDataButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        stackView.addArrangedSubview(messageLabel)
        stackView.addArrangedSubview(autofillDataButton)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 38),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor, constant: -24),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
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
    
    func makeUIView(context: Context) -> TestModeAutofillBannerView {
        TestModeAutofillBannerView(context: bannerContext, didTapAutofill: {})
    }
    
    func updateUIView(_ uiView: TestModeAutofillBannerView, context: Context) {}
}

struct TestModeAutofillBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TestModeAutofillBannerViewRepresentable(bannerContext: .account)
                .frame(height: 38)
            
            TestModeAutofillBannerViewRepresentable(bannerContext: .otp)
                .frame(height: 38)
        }
    }
}

#endif
