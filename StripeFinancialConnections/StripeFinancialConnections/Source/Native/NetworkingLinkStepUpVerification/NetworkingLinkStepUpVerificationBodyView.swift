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

    init(email: String) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                otpTextField,
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
}

private func CreateEmailLabel(email: String) -> UIView {
    let emailLabel = UILabel()
    emailLabel.text = "Signing in as \(email)" // TODO(kgaidis): wrap with localizable strings
    emailLabel.font = .stripeFont(forTextStyle: .captionTight)
    emailLabel.textColor = .textSecondary
    return emailLabel
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct NetworkingLinkStepUpVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkStepUpVerificationBodyView {
        NetworkingLinkStepUpVerificationBodyView(
            email: "test@stripe.com"
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
