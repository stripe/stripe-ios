//
//  NetworkingLinkStepUpVerificationBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/16/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkStepUpVerificationBodyViewDelegate: AnyObject {
    func networkingLinkStepUpVerificationBodyView(
        _ view: NetworkingLinkStepUpVerificationBodyView,
        didEnterValidOTPCode otpCode: String
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkStepUpVerificationBodyView: UIView {

    private let email: String
    private let didSelectResendCode: () -> Void
    weak var delegate: NetworkingLinkStepUpVerificationBodyViewDelegate?

    private(set) lazy var otpTextField: UITextField = {
       let textField = InsetTextField()
        textField.textColor = .textPrimary
        textField.placeholder = "OTP"
        textField.keyboardType = .numberPad
        textField.layer.cornerRadius = 8
        textField.layer.borderColor = UIColor.textBrand.cgColor
        textField.layer.borderWidth = 2.0
        textField.addTarget(
            self,
            action: #selector(otpTextFieldDidChange),
            for: .editingChanged
        )
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: 56)
        ])

        return textField
    }()

    private lazy var footnoteHorizontalStackView: UIStackView = {
        let footnoteHorizontalStackView = UIStackView()
        footnoteHorizontalStackView.axis = .horizontal
        footnoteHorizontalStackView.spacing = 8
        footnoteHorizontalStackView.alignment = .center
        return footnoteHorizontalStackView
    }()

    init(
        email: String,
        didSelectResendCode: @escaping () -> Void
    ) {
        self.email = email
        self.didSelectResendCode = didSelectResendCode
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                otpTextField,
                footnoteHorizontalStackView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
        addAndPinSubview(verticalStackView)

        setupFootnoteView(isResendingCode: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func otpTextFieldDidChange() {
        guard let otp = otpTextField.text else {
            return
        }

        if otp.count == 6 && Int(otp) != nil {
            delegate?.networkingLinkStepUpVerificationBodyView(
                self,
                didEnterValidOTPCode: otp
            )
        }
    }

    func isResendingCode(_ isResendingCode: Bool) {
        setupFootnoteView(isResendingCode: isResendingCode)
    }

    private func setupFootnoteView(isResendingCode: Bool) {
        // clear all previous state
        footnoteHorizontalStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        footnoteHorizontalStackView.addArrangedSubview(
            CreateEmailLabel(email: email)
        )
        footnoteHorizontalStackView.addArrangedSubview(
            CreateCreateDotLabel()
        )
        footnoteHorizontalStackView.addArrangedSubview(
            CreateResendCodeLabel(
                isEnabled: !isResendingCode,
                didSelect: didSelectResendCode
            )
        )
        if isResendingCode {
            footnoteHorizontalStackView.addArrangedSubview(
                CreateResendCodeLoadingView()
            )
            let spacerView = UIView()
            footnoteHorizontalStackView.addArrangedSubview(spacerView)
        }
    }
}

private func CreateEmailLabel(email: String) -> UIView {
    let emailLabel = UILabel()
    emailLabel.text = "\(email)"
    emailLabel.font = .stripeFont(forTextStyle: .captionTight)
    emailLabel.textColor = .textSecondary
    return emailLabel
}

private func CreateCreateDotLabel() -> UIView {
    let dotLabel = UILabel()
    dotLabel.text = "•"
    dotLabel.font = .stripeFont(forTextStyle: .captionTight)
    dotLabel.textColor = .textDisabled
    return dotLabel
}

@available(iOSApplicationExtension, unavailable)
private func CreateResendCodeLabel(isEnabled: Bool, didSelect: @escaping () -> Void) -> UIView {
    let resendCodeLabel = ClickableLabel(
        font: .stripeFont(forTextStyle: .captionTightEmphasized),
        boldFont: .stripeFont(forTextStyle: .captionTightEmphasized),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized),
        textColor: .textDisabled,
        alignCenter: false
    )
    let text = "Resend code" // TODO(kgaidis): localize
    if isEnabled {
        resendCodeLabel.setText(
            "[\(text)](https://www.just-fire-action.com)",
            action: { _ in
                didSelect()
            }
        )
    } else {
        resendCodeLabel.setText(text)
    }
    return resendCodeLabel
}

private func CreateResendCodeLoadingView() -> UIView {
    let activityIndicator = ActivityIndicator(size: .medium)
    activityIndicator.color = .textDisabled
    activityIndicator.startAnimating()

    // `ActivityIndicator` is hard-coded to have specific sizes, so here we scale it to our needs
    let mediumIconDiameter: CGFloat = 20
    let desiredIconDiameter: CGFloat = 12
    let transform = CGAffineTransform(scaleX: desiredIconDiameter / mediumIconDiameter, y: desiredIconDiameter / mediumIconDiameter)
    activityIndicator.transform = transform
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        activityIndicator.widthAnchor.constraint(equalToConstant: desiredIconDiameter),
        activityIndicator.heightAnchor.constraint(equalToConstant: desiredIconDiameter),
    ])
    return activityIndicator
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct NetworkingLinkStepUpVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkStepUpVerificationBodyView {
        NetworkingLinkStepUpVerificationBodyView(
            email: "test@stripe.com",
            didSelectResendCode: {}
        )
    }

    func updateUIView(_ uiView: NetworkingLinkStepUpVerificationBodyView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct NetworkingLinkStepUpVerificationBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            NetworkingLinkStepUpVerificationBodyViewUIViewRepresentable()
                .frame(maxHeight: 100)
                .padding()
            Spacer()
        }
    }
}

#endif

private class InsetTextField: UITextField { // TODO(kgaidis): cleanup/delete after using Stripe's components

    private let padding = UIEdgeInsets(
        top: 0,
        left: 10,
        bottom: 0,
        right: 10
    )

    override open func textRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(
        forBounds bounds: CGRect
    ) -> CGRect {
        return bounds.inset(by: padding)
    }
}
