//
//  PhoneTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol PhoneTextFieldDelegate: AnyObject {
    func phoneTextField(
        _ phoneTextField: PhoneTextField,
        didChangeEmailAddress emailAddress: String,
        isValid: Bool
    )
}

final class PhoneTextField: UIView {

    fileprivate lazy var textField: RoundedTextField = {
        let textField = RoundedTextField(
            placeholder: "Phone number" // TODO(kgaidis) localize
        )
        textField.textField.keyboardType = .phonePad
        textField.textField.textContentType = .telephoneNumber
        textField.textField.autocapitalizationType = .none
        textField
            .containerHorizontalStackView
            .insertArrangedSubview(countryCodeView, at: 0)
        textField
            .containerHorizontalStackView
            .directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 4,
                leading: 4,
                bottom: 4,
                trailing: 16
            )
        textField.delegate = self
        return textField
    }()
    private var countryCodeView: UIView = {
        let countryCodeView = UIView()
        countryCodeView.backgroundColor = .backgroundOffset
        countryCodeView.layer.cornerRadius = 8
        // 72 x 48
        countryCodeView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countryCodeView.widthAnchor.constraint(equalToConstant: 72),
            countryCodeView.heightAnchor.constraint(equalToConstant: 48),
        ])
        return countryCodeView
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
    private var phoneNumber: PhoneNumber? {
        // TODO(kgaidis): adjust the US country code
        return PhoneNumber(number: text, countryCode: "US")
    }
    var isPhoneNumberValid: Bool {
        if let phoneNumber {
            return phoneNumber.isComplete
        } else {
            // Assume user has entered a format or for a region the SDK doesn't know about.
            // Return valid as long as it's non-empty and let the server decide.
            return true
        }
    }

    weak var delegate: PhoneTextFieldDelegate?

    init() {
        super.init(frame: .zero)
        addAndPinSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func endEditing(_ force: Bool) -> Bool {
        _ = textField.endEditing(force)
        return super.endEditing(force)
    }

    private func textDidChange() {
        // format the text (ex. "401500" -> "(401) 500")
        textField.text = phoneNumber?.string(as: .national) ?? text

        textField.errorText = nil
        if !isPhoneNumberValid {
            // only show error messages once
            // user cleared
            if didEndEditingOnce {
                if text.isEmpty {
                    // no error message if empty
                } else {
                    textField.errorText = "Your mobile phone number is incomplete." // TODO(kgaidis): localize
                }
            }
        }

        delegate?.phoneTextField(
            self,
            didChangeEmailAddress: text,
            isValid: isPhoneNumberValid
        )
    }
}

extension PhoneTextField: RoundedTextFieldDelegate {

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

    func roundedTextFieldDidEndEditing(
        _ textField: RoundedTextField
    ) {
        didEndEditingOnce = true
    }
}

#if DEBUG

import SwiftUI

private struct PhoneTextFieldUIViewRepresentable: UIViewRepresentable {

    let text: String

    func makeUIView(context: Context) -> PhoneTextField {
        PhoneTextField()
    }

    func updateUIView(
        _ phoneTextField: PhoneTextField,
        context: Context
    ) {
        phoneTextField.text = text
        phoneTextField.didEndEditingOnce = true
        phoneTextField.roundedTextField(
            phoneTextField.textField,
            textDidChange: text
        )
    }
}

struct PhoneTextField_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                PhoneTextFieldUIViewRepresentable(
                    text: ""
                ).frame(height: 56)

                PhoneTextFieldUIViewRepresentable(
                    text: "4015006000"
                ).frame(height: 56)

                PhoneTextFieldUIViewRepresentable(
                    text: "401500600"
                ).frame(height: 90)

                PhoneTextFieldUIViewRepresentable(
                    text: "40150060003435"
                ).frame(height: 90)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
