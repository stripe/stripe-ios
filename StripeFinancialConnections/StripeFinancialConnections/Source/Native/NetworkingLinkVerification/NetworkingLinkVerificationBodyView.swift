//
//  NetworkingLinkVerificationBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/9/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkVerificationBodyViewDelegate: AnyObject {
    func networkingLinkVerificationBodyView(
        _ view: NetworkingLinkVerificationBodyView,
        didEnterValidOTPCode otpCode: String
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkVerificationBodyView: UIView {

    weak var delegate: NetworkingLinkVerificationBodyViewDelegate?

    private lazy var otpVerticalStackView: UIStackView = {
        let otpVerticalStackView = UIStackView(
            arrangedSubviews: [
                otpTextField,
            ]
        )
        otpVerticalStackView.axis = .vertical
        otpVerticalStackView.spacing = 8
        return otpVerticalStackView
    }()
    // TODO(kgaidis): make changes to `OneTimeCodeTextField` to
    // make the font larger
    private(set) lazy var otpTextField: OneTimeCodeTextField = {
        let otpTextField = OneTimeCodeTextField(numberOfDigits: 6, theme: theme)
        otpTextField.tintColor = .textBrand
        otpTextField.addTarget(self, action: #selector(otpTextFieldDidChange), for: .valueChanged)
        return otpTextField
    }()
    private lazy var theme: ElementsUITheme = {
        var theme: ElementsUITheme = .default
        theme.colors = {
            var colors = ElementsUITheme.Color()
            colors.border = .borderNeutral
            return colors
        }()
        return theme
    }()
    private var lastErrorView: UIView?

    init(email: String) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                otpVerticalStackView,
                CreateEmailLabel(email: email),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func otpTextFieldDidChange() {
        showErrorText(nil) // clear the error

        if otpTextField.isComplete {
            delegate?.networkingLinkVerificationBodyView(self, didEnterValidOTPCode: otpTextField.value)
        }
    }

    func showErrorText(_ errorText: String?) {
        lastErrorView?.removeFromSuperview()
        lastErrorView = nil

        if let errorText = errorText {
            // TODO(kgaidis): rename & move `ManualEntryErrorView` to be more generic
            let errorView = ManualEntryErrorView(text: errorText)
            self.lastErrorView = errorView
            otpVerticalStackView.addArrangedSubview(errorView)
        }
    }
}

private func CreateEmailLabel(email: String) -> UIView {
    let emailLabel = UILabel()
    emailLabel.text = String(format: STPLocalizedString("Signing in as %@", "A footnote that explains the user that when they enter an one-time-password code (OTP), they will be signing in as the email in this footnote. '%@' is replaced with an email, for examle: 'Signing in as user@gmail.com'."), email)
    emailLabel.font = .stripeFont(forTextStyle: .captionTight)
    emailLabel.textColor = .textSecondary
    return emailLabel
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct NetworkingLinkVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkVerificationBodyView {
        NetworkingLinkVerificationBodyView(
            email: "test@stripe.com"
        )
    }

    func updateUIView(_ uiView: NetworkingLinkVerificationBodyView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct NetworkingLinkVerificationBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            NetworkingLinkVerificationBodyViewUIViewRepresentable()
                .frame(maxHeight: 100)
                .padding()
            Spacer()
        }
    }
}

#endif
