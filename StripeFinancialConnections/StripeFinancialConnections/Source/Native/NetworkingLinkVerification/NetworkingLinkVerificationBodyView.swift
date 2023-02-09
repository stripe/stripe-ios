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
    func networkingLinkVerificationBodyView(_ view: NetworkingLinkVerificationBodyView, didEnterValidOTP otp: String)
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkVerificationBodyView: UIView {

    weak var delegate: NetworkingLinkVerificationBodyViewDelegate?

    private lazy var otpTextField: UITextField = {
       let textField = InsetTextField()
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

        if otp.count == 6 {
            delegate?.networkingLinkVerificationBodyView(self, didEnterValidOTP: otp)
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
