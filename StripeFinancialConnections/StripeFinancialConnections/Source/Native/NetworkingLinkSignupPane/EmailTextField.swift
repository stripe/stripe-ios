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

    fileprivate lazy var textField: RoundedTextField = {
        let textField = RoundedTextField(
            placeholder: "Email address" // TODO(kgaidis) localize
        )
        textField.textField.keyboardType = .emailAddress
        textField.textField.textContentType = .emailAddress
        textField.textField.autocapitalizationType = .none
        textField
            .containerHorizontalStackView
            .addArrangedSubview(activityIndicator)
        textField.delegate = self
        return textField
    }()
    private let activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .medium)
        activityIndicator.setContentCompressionResistancePriority(.required, for: .horizontal)
        activityIndicator.color = .iconActionPrimary
        return activityIndicator
    }()
    // we will only start validating as user
    // types once editing ends
    fileprivate var didEndEditingOnce = false

    var text: String {
        set {
            textField.text = newValue
            textDidChange()
        }
        get {
            textField.text
        }
    }
    var isEmailValid: Bool {
        return STPEmailAddressValidator.stringIsValidEmailAddress(text)
    }

    weak var delegate: EmailTextFieldDelegate?

    init() {
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

    override func endEditing(_ force: Bool) -> Bool {
        _ = textField.endEditing(force)
        return super.endEditing(force)
    }

    private func textDidChange() {
        textField.errorText = nil

        if !isEmailValid {
            // only show error messages once
            // user cleared
            if didEndEditingOnce {
                if text.isEmpty {
                    // no error message if empty
                } else {
                    // only
                    textField.errorText = "Your email address is invalid." // TODO(kgaidis): localize
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
    }
}

#if DEBUG

import SwiftUI

private struct EmailTextFieldUIViewRepresentable: UIViewRepresentable {

    let text: String
    let isLoading: Bool

    func makeUIView(context: Context) -> EmailTextField {
        EmailTextField()
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
                    isLoading: false
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "test@test.com",
                    isLoading: false
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "test@test-very-long-name-thats-very-long.com",
                    isLoading: true
                ).frame(height: 56)

                EmailTextFieldUIViewRepresentable(
                    text: "wrongemail@wronger",
                    isLoading: false
                ).frame(height: 90)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
