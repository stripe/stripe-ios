//
//  NetworkingSaveToLinkBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/14/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingSaveToLinkVerificationBodyViewDelegate: AnyObject {
    func networkingSaveToLinkVerificationBodyView(
        _ view: NetworkingSaveToLinkVerificationBodyView,
        didEnterValidOTPCode otpCode: String
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingSaveToLinkVerificationBodyView: UIView {

    weak var delegate: NetworkingSaveToLinkVerificationBodyViewDelegate?

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
            delegate?.networkingSaveToLinkVerificationBodyView(
                self,
                didEnterValidOTPCode: otp
            )
        }
    }
}

private func CreateEmailLabel(email: String) -> UIView {
    let emailLabel = UILabel()
    emailLabel.text = String(format: STPLocalizedString("Signing in as %@", "A footnote that explains to the user that they are signing in as a user with a specific e-mail. '%@' is replaced with an e-mail, for example, 'Signing in as test@test.com'"), email)
    emailLabel.font = .stripeFont(forTextStyle: .captionTight)
    emailLabel.textColor = .textSecondary
    return emailLabel
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct NetworkingSaveToLinkVerificationBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingSaveToLinkVerificationBodyView {
        NetworkingSaveToLinkVerificationBodyView(
            email: "test@stripe.com"
        )
    }

    func updateUIView(_ uiView: NetworkingSaveToLinkVerificationBodyView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct NetworkingSaveToLinkVerificationBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            NetworkingSaveToLinkVerificationBodyViewUIViewRepresentable()
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
