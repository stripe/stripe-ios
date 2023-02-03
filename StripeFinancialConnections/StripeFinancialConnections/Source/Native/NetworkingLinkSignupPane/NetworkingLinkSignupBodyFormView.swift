//
//  NetworkingLinkSignupBodyFormView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/24/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkSignupBodyFormViewDelegate: AnyObject {
    func networkingLinkSignupBodyFormViewDidEnterValidEmail(_ view: NetworkingLinkSignupBodyFormView)
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkSignupBodyFormView: UIView {

    weak var delegate: NetworkingLinkSignupBodyFormViewDelegate?

    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                emailAddressTextField
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        return verticalStackView
    }()
    private(set) lazy var emailAddressTextField: UITextField = {
        let emailAddressTextField = InsetTextField()
        emailAddressTextField.placeholder = "Email address (needs to end with .com)"
        emailAddressTextField.layer.cornerRadius = 8
        emailAddressTextField.layer.borderColor = UIColor.textBrand.cgColor
        emailAddressTextField.layer.borderWidth = 2.0
        emailAddressTextField.delegate = self
        emailAddressTextField.addTarget(
            self,
            action: #selector(emailAddressTextFieldDidChange),
            for: .editingChanged
        )
        NSLayoutConstraint.activate([
            emailAddressTextField.heightAnchor.constraint(equalToConstant: 56)
        ])
        return emailAddressTextField
    }()
    private(set) lazy var phoneNumberTextField: UITextField = {
        let phoneNumberTextField = InsetTextField()
        phoneNumberTextField.placeholder = "Phone number"
        phoneNumberTextField.layer.cornerRadius = 8
        phoneNumberTextField.layer.borderColor = UIColor.textBrand.cgColor
        phoneNumberTextField.layer.borderWidth = 2.0
        phoneNumberTextField.delegate = self
        phoneNumberTextField.addTarget(
            self,
            action: #selector(phoneNumberTextFieldDidChange),
            for: .editingChanged
        )
        NSLayoutConstraint.activate([
            phoneNumberTextField.heightAnchor.constraint(equalToConstant: 56)
        ])
        return phoneNumberTextField
    }()

    init() {
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPhoneNumberTextFieldIfNeeded() {
        guard phoneNumberTextField.superview == nil else {
            return  // already added
        }
        verticalStackView.addArrangedSubview(phoneNumberTextField)
        // TODO(kgaidis): also add a little label together with phone numebr text field
    }

    @objc private func emailAddressTextFieldDidChange() {
        guard let emailAddress = emailAddressTextField.text else {
            return
        }

        // TODO(kgaidis): validate e-mail

        if emailAddress.hasSuffix(".com") {
            delegate?.networkingLinkSignupBodyFormViewDidEnterValidEmail(self)
        }
    }

    @objc private func phoneNumberTextFieldDidChange() {
        print("\(phoneNumberTextField.text!)")
    }
}

@available(iOSApplicationExtension, unavailable)
extension NetworkingLinkSignupBodyFormView: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {

    }

    func textFieldDidEndEditing(_ textField: UITextField) {

    }
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct NetworkingLinkSignupBodyFormViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkSignupBodyFormView {
        NetworkingLinkSignupBodyFormView()
    }

    func updateUIView(_ uiView: NetworkingLinkSignupBodyFormView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct NetworkingLinkSignupBodyFormView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            NetworkingLinkSignupBodyFormViewUIViewRepresentable()
                .frame(maxHeight: 200)
                .padding()
            Spacer()
        }
    }
}

#endif

private class InsetTextField: UITextField {

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
