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

final class NetworkingLinkStepUpVerificationBodyView: UIView {

    private let email: String
    private let didSelectResendCode: () -> Void

    private lazy var footnoteHorizontalStackView: UIStackView = {
        let footnoteHorizontalStackView = UIStackView()
        footnoteHorizontalStackView.axis = .horizontal
        footnoteHorizontalStackView.spacing = 8
        footnoteHorizontalStackView.alignment = .center
        return footnoteHorizontalStackView
    }()

    init(
        email: String,
        otpView: UIView,
        didSelectResendCode: @escaping () -> Void
    ) {
        self.email = email
        self.didSelectResendCode = didSelectResendCode
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                otpView,
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
    let emailLabel = AttributedLabel(
        font: .label(.medium),
        textColor: .textSecondary
    )
    emailLabel.text = "\(email)"
    return emailLabel
}

private func CreateCreateDotLabel() -> UIView {
    let dotLabel = AttributedLabel(
        font: .label(.medium),
        textColor: .textDisabled
    )
    dotLabel.text = "•"
    return dotLabel
}

private func CreateResendCodeLabel(isEnabled: Bool, didSelect: @escaping () -> Void) -> UIView {
    let resendCodeLabel = AttributedTextView(
        font: .label(.medium),
        boldFont: .label(.mediumEmphasized),
        linkFont: .label(.mediumEmphasized),
        textColor: .textDisabled,
        alignCenter: false
    )
    let text = STPLocalizedString(
        "Resend code",
        "The title of a button that allows a user to request a one-time-password (OTP) again in case they did not receive it."
    )
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

private struct NetworkingLinkStepUpVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkStepUpVerificationBodyView {
        NetworkingLinkStepUpVerificationBodyView(
            email: "test@stripe.com",
            otpView: UIView(),
            didSelectResendCode: {}
        )
    }

    func updateUIView(_ uiView: NetworkingLinkStepUpVerificationBodyView, context: Context) {}
}

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
