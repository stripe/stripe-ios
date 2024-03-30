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

    private let didSelectResendCode: () -> Void

    // `UIStackView` is used only for padding
    private lazy var footnoteStackView: UIStackView = {
        let footnoteStackView = UIStackView()
        footnoteStackView.axis = .vertical
        footnoteStackView.alignment = .center
        footnoteStackView.isLayoutMarginsRelativeArrangement = true
        footnoteStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 0,
            bottom: 8,
            trailing: 0
        )
        return footnoteStackView
    }()

    init(
        otpView: UIView,
        didSelectResendCode: @escaping () -> Void
    ) {
        self.didSelectResendCode = didSelectResendCode
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                otpView,
                footnoteStackView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        addAndPinSubview(verticalStackView)

        showResendCodeLabel(true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showResendCodeLabel(_ show: Bool) {
        // clear all previous state
        footnoteStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if show {
            footnoteStackView.addArrangedSubview(
                CreateResendCodeLabel(
                    didSelect: didSelectResendCode
                )
            )
        }
    }
}

private func CreateResendCodeLabel(
    didSelect: @escaping () -> Void
) -> UIView {
    let resendCodeLabel = AttributedTextView(
        font: .label(.medium),
        boldFont: .label(.mediumEmphasized),
        linkFont: .label(.mediumEmphasized),
        textColor: .textActionPrimary,
        showLinkUnderline: false,
        alignCenter: false
    )
    let text = STPLocalizedString(
        "Resend code",
        "The title of a button that allows a user to request a one-time-password (OTP) again in case they did not receive it."
    )
    resendCodeLabel.setText(
        // we add a fake link to fire the `action` closure
        "[\(text)](https://www.just-fire-action.com)",
        action: { _ in
            didSelect()
        }
    )
    return resendCodeLabel
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkStepUpVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkStepUpVerificationBodyView {
        NetworkingLinkStepUpVerificationBodyView(
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
