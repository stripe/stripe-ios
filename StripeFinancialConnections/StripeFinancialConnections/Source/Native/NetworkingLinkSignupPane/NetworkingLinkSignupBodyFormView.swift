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

protocol NetworkingLinkSignupBodyFormViewDelegate: AnyObject {
    func networkingLinkSignupBodyFormView(
        _ view: NetworkingLinkSignupBodyFormView,
        didEnterValidEmailAddress emailAddress: String
    )
    func networkingLinkSignupBodyFormViewDidUpdateFields(
        _ view: NetworkingLinkSignupBodyFormView
    )
}

final class NetworkingLinkSignupBodyFormView: UIView {

    private let accountholderPhoneNumber: String?
    weak var delegate: NetworkingLinkSignupBodyFormViewDelegate?

    private lazy var verticalStackView: UIStackView = {
       let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.addArrangedSubview(emailTextField)
        verticalStackView.addArrangedSubview(phoneTextField)
        return verticalStackView
    }()
    private(set) lazy var emailTextField: EmailTextField = {
       let emailTextField = EmailTextField()
        emailTextField.delegate = self
        return emailTextField
    }()
    private(set) lazy var phoneTextField: PhoneTextField = {
       let phoneTextField = PhoneTextField(defaultPhoneNumber: accountholderPhoneNumber)
        phoneTextField.delegate = self
        return phoneTextField
    }()
    private var debounceEmailTimer: Timer?
    private var lastValidEmail: String?

    init(accountholderPhoneNumber: String?) {
        self.accountholderPhoneNumber = accountholderPhoneNumber
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
        phoneTextField.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // returns `true` if the phone number field was shown for the first time
    func showPhoneNumberFieldIfNeeded() -> Bool {
        let isPhoneNumberFieldHidden = phoneTextField.isHidden
        guard isPhoneNumberFieldHidden else {
            return false // phone number field is already shown
        }
        phoneTextField.isHidden = false
        return true // phone number is shown for the first time
    }

    func prefillEmailAddress(_ emailAddress: String?) {
        guard let emailAddress = emailAddress, !emailAddress.isEmpty else {
            return
        }
        emailTextField.text = emailAddress
    }

    func beginEditingEmailAddressField() {
        _ = emailTextField.becomeFirstResponder()
    }

    func endEditingEmailAddressField() {
        _ = emailTextField.endEditing(true)
    }

    func beginEditingPhoneNumberField() {
        _ = phoneTextField.becomeFirstResponder()
    }
}

// MARK: - EmailTextFieldDelegate

extension NetworkingLinkSignupBodyFormView: EmailTextFieldDelegate {

    func emailTextField(
        _ emailTextField: EmailTextField,
        didChangeEmailAddress emailAddress: String,
        isValid: Bool
    ) {
        delegate?.networkingLinkSignupBodyFormViewDidUpdateFields(self)

        if isValid {
            debounceEmailTimer?.invalidate()
            debounceEmailTimer = Timer.scheduledTimer(
                // TODO(kgaidis): discuss this logic w/ team; Stripe.js is constant 0.3
                //
                // a valid e-mail will transition the user to the phone number
                // field (sometimes prematurely), so we increase debounce if
                // if there's a high chance the e-mail is not yet finished
                // being typed (high chance of not finishing == not .com suffix)
                withTimeInterval: emailAddress.hasSuffix(".com") ? 0.3 : 1.0,
                repeats: false
            ) { [weak self] _ in
                guard let self = self else { return }
                if
                    // make sure the email inputted is still valid
                    // even after the debounce
                    self.emailTextField.isEmailValid,
                    // `lastValidEmail` ensures that we only
                    // fire the delegate ONCE per unique valid email
                        emailAddress != self.lastValidEmail
                {
                    self.lastValidEmail = emailAddress
                    self.delegate?.networkingLinkSignupBodyFormView(
                        self,
                        didEnterValidEmailAddress: emailAddress
                    )
                }
            }
        } else {
            // errors are displayed automatically by the component
            lastValidEmail = nil
        }
    }

    func emailTextFieldUserDidPressReturnKey(_ textField: EmailTextField) {
        _ = textField.endEditing(true)
        // move keyboard to phone field if phone is not valid,
        // otherwise just dismiss it
        if !phoneTextField.isHidden, !phoneTextField.isPhoneNumberValid {
            _ = phoneTextField.becomeFirstResponder()
        }
    }
}

// MARK: - PhoneTextFieldDelegate

extension NetworkingLinkSignupBodyFormView: PhoneTextFieldDelegate {
    func phoneTextField(
        _ phoneTextField: PhoneTextField,
        didChangePhoneNumber phoneNumber: PhoneNumber?
    ) {
        delegate?.networkingLinkSignupBodyFormViewDidUpdateFields(self)
    }
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkSignupBodyFormViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> NetworkingLinkSignupBodyFormView {
        NetworkingLinkSignupBodyFormView(accountholderPhoneNumber: nil)
    }

    func updateUIView(_ uiView: NetworkingLinkSignupBodyFormView, context: Context) {}
}

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
