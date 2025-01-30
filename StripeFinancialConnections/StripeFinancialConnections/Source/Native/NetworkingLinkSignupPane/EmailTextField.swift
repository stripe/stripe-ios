//
//  EmailTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol EmailTextFieldDelegate: AnyObject {
    func emailTextField(
        _ emailTextField: EmailTextField,
        didChangeEmailAddress emailAddress: String,
        isValid: Bool
    )
    func emailTextFieldUserDidPressReturnKey(_ textField: EmailTextField)
}

final class EmailTextField: UIView {

    private let appearance: FinancialConnectionsAppearance
    fileprivate lazy var textField: RoundedTextField = {
        let textField = RoundedTextField(
            placeholder: STPLocalizedString(
                "Email address",
                "The title of a user-input-field that appears when a user is signing up to Link (a payment service). It instructs user to type an email address."
            ),
            showDoneToolbar: true,
            appearance: appearance
        )
        textField.textField.keyboardType = .emailAddress
        textField.textField.textContentType = .emailAddress
        textField.textField.autocapitalizationType = .none
        textField
            .containerHorizontalStackView
            .addArrangedSubview(activityIndicator)
        textField.delegate = self
        textField.textField.accessibilityIdentifier = "email_text_field"
        return textField
    }()
    private lazy var activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .medium)
        activityIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        activityIndicator.color = appearance.colors.spinner
        return activityIndicator
    }()
    fileprivate var didEndEditingOnce = false

    var text: String {
        get {
            textField.text
        }
        set {
            textField.text = newValue
            textDidChange()
        }
    }
    var isEmailValid: Bool {
        return STPEmailAddressValidator.stringIsValidEmailAddress(text)
    }

    weak var delegate: EmailTextFieldDelegate?

    init(appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        addAndPinSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoadingView(_ show: Bool) {
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func endEditing(_ force: Bool) -> Bool {
        return textField.endEditing(force)
    }

    private func textDidChange() {
        textField.errorText = nil
        if !isEmailValid {
            // do not show error messages unless the user
            // stopped editing the text field at least once
            if didEndEditingOnce {
                if text.isEmpty {
                    // no error message if empty
                } else {
                    textField.errorText = STPLocalizedString("Your email address is invalid.", "An error message that instructs the user to keep typing their email address in a user-input field.")
                }
            }
        }

        delegate?.emailTextField(
            self,
            didChangeEmailAddress: text,
            isValid: isEmailValid
        )
    }
}

extension EmailTextField: RoundedTextFieldDelegate {

    func roundedTextField(
        _ textField: RoundedTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return true
    }

    func roundedTextField(
        _ textField: RoundedTextField,
        textDidChange text: String
    ) {
        textDidChange()
    }

    func roundedTextFieldUserDidPressReturnKey(_ textField: RoundedTextField) {
        delegate?.emailTextFieldUserDidPressReturnKey(self)
    }

    func roundedTextFieldDidEndEditing(_ textField: RoundedTextField) {
        didEndEditingOnce = true
        // check whether we need to update error state
        textDidChange()
    }
}

#if DEBUG

import SwiftUI

private struct EmailTextFieldUIViewRepresentable: UIViewRepresentable {

    let text: String
    let isLoading: Bool
    let appearance: FinancialConnectionsAppearance

    func makeUIView(context: Context) -> EmailTextField {
        EmailTextField(appearance: appearance)
    }

    func updateUIView(
        _ emailTextField: EmailTextField,
        context: Context
    ) {
        emailTextField.text = text
        emailTextField.showLoadingView(isLoading)
        emailTextField.didEndEditingOnce = true
        emailTextField.roundedTextField(
            emailTextField.textField,
            textDidChange: text
        )
    }
}

struct EmailTextField_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                EmailTextFieldUIViewRepresentable(
                    text: "",
                    isLoading: false,
                    appearance: .stripe
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "test@test.com",
                    isLoading: false,
                    appearance: .stripe
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "test@test-very-long-name-thats-very-long.com",
                    isLoading: true,
                    appearance: .stripe
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "wrongemail@wronger",
                    isLoading: false,
                    appearance: .stripe
                ).frame(height: 90)

                EmailTextFieldUIViewRepresentable(
                    text: "light@theme.com",
                    isLoading: true,
                    appearance: .stripe
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "linklight@theme.com",
                    isLoading: true,
                    appearance: .link
                ).frame(height: 56)

                Spacer()
            }
            .padding()
            .background(Color(FinancialConnectionsAppearance.Colors.background))
        }
    }
}

#endif
