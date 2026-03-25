//
//  LinkSignupFormView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/24/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol LinkSignupFormViewDelegate: AnyObject {
    func linkSignupFormView(
        _ view: LinkSignupFormView,
        didEnterValidEmailAddress emailAddress: String
    )
    func linkSignupFormViewDidUpdateFields(
        _ view: LinkSignupFormView
    )
}

final class LinkSignupFormView: UIView {

    private let accountholderPhoneNumber: String?
    private let appearance: FinancialConnectionsAppearance
    weak var delegate: LinkSignupFormViewDelegate?

    private lazy var verticalStackView: UIStackView = {
       let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        verticalStackView.addArrangedSubview(emailTextField)
        verticalStackView.addArrangedSubview(phoneTextField)
        return verticalStackView
    }()
    private(set) lazy var emailTextField: EmailTextField = {
       let emailTextField = EmailTextField(appearance: appearance)
        emailTextField.delegate = self
        return emailTextField
    }()
    private(set) lazy var phoneTextField: PhoneTextField = {
       let phoneTextField = PhoneTextField(defaultPhoneNumber: accountholderPhoneNumber, appearance: appearance)
        phoneTextField.delegate = self
        return phoneTextField
    }()
    private var debounceEmailTimer: Timer?
    private var lastValidEmail: String?

    init(accountholderPhoneNumber: String?, appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
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

    func showAndEditPhoneNumberFieldIfNeeded() {
        let didShowPhoneNumberFieldForTheFirstTime = showPhoneNumberFieldIfNeeded()
        // in case user needs to slowly re-type the e-mail,
        // we want to only jump to the phone number the
        // first time they enter the e-mail
        if didShowPhoneNumberFieldForTheFirstTime {
            let didPrefillPhoneNumber = (phoneTextField.phoneNumber?.number ?? "").count > 1
            if !didPrefillPhoneNumber {
                // this disables the "Phone" label animating (we don't want that animation here)
                UIView.performWithoutAnimation {
                    // auto-focus the non-prefilled phone field
                    beginEditingPhoneNumberField()
                }
            } else {
                // user is done with e-mail AND phone number, so dismiss the keyboard
                // so they can see the "Save to Link" button
                endEditingEmailAddressField()
            }
        }
    }

    func prefillEmailAddress(_ emailAddress: String?) {
        guard let emailAddress = emailAddress, !emailAddress.isEmpty else {
            return
        }
        emailTextField.text = emailAddress
    }

    func prefillPhoneNumber(_ phoneNumber: String?) {
        guard let phoneNumber, !phoneNumber.isEmpty else {
            return
        }
        phoneTextField.text = phoneNumber
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

extension LinkSignupFormView: EmailTextFieldDelegate {

    func emailTextField(
        _ emailTextField: EmailTextField,
        didChangeEmailAddress emailAddress: String,
        isValid: Bool
    ) {
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
                self.delegate?.linkSignupFormViewDidUpdateFields(self)

                if
                    // make sure the email inputted is still valid
                    // even after the debounce
                    self.emailTextField.isEmailValid,
                    // `lastValidEmail` ensures that we only
                    // fire the delegate ONCE per unique valid email
                        emailAddress != self.lastValidEmail
                {
                    self.lastValidEmail = emailAddress
                    self.delegate?.linkSignupFormView(
                        self,
                        didEnterValidEmailAddress: emailAddress
                    )
                }
            }
        } else {
            // errors are displayed automatically by the component
            delegate?.linkSignupFormViewDidUpdateFields(self)
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

extension LinkSignupFormView {
    var email: String {
        emailTextField.text
    }

    var phoneNumber: String {
        phoneTextField.phoneNumber?.string(as: .e164) ?? ""
    }

    var countryCode: String {
        phoneTextField.phoneNumber?.countryCode ?? "US"
    }
}

// MARK: - PhoneTextFieldDelegate

extension LinkSignupFormView: PhoneTextFieldDelegate {
    func phoneTextField(
        _ phoneTextField: PhoneTextField,
        didChangePhoneNumber phoneNumber: PhoneNumber?
    ) {
        delegate?.linkSignupFormViewDidUpdateFields(self)
    }
}

#if DEBUG

import SwiftUI

private struct NetworkingLinkSignupBodyFormViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> LinkSignupFormView {
        LinkSignupFormView(accountholderPhoneNumber: nil, appearance: .stripe)
    }

    func updateUIView(_ uiView: LinkSignupFormView, context: Context) {}
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
