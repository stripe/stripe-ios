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
        didChangePhoneNumber phoneNumber: PhoneNumber?
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
            .insertArrangedSubview(countryCodeSelectorView, at: 0)
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
    private let countryCodeSelectorView: PhoneCountryCodeSelectorView
    // we will only start validating as user
    // types once editing ends
    fileprivate var didEndEditingOnce = false

    var text: String {
        set {
            textField.text = newValue
            phoneNumberDidChange()
        }
        get {
            textField.text
        }
    }
    var phoneNumber: PhoneNumber? {
        return PhoneNumber(number: text, countryCode: countryCodeSelectorView.selectedCountryCode)
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

    init(defaultPhoneNumber: String?) {
        var defaultPhoneNumber = defaultPhoneNumber
        var defaultCountryCode: String?
        if let _defaultPhoneNumber = defaultPhoneNumber, let e164PhoneNumber = PhoneNumber.fromE164(_defaultPhoneNumber) {
            defaultPhoneNumber = e164PhoneNumber.number
            defaultCountryCode = e164PhoneNumber.countryCode
        }
        self.countryCodeSelectorView = PhoneCountryCodeSelectorView(
            defaultCountryCode: defaultCountryCode
        )
        super.init(frame: .zero)
        countryCodeSelectorView.delegate = self
        addAndPinSubview(textField)
        text = defaultPhoneNumber ?? ""
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func endEditing(_ force: Bool) -> Bool {
        return textField.endEditing(force)
    }

    private func phoneNumberDidChange() {
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

        delegate?.phoneTextField(self, didChangePhoneNumber: phoneNumber)
    }
}

// MARK: - RoundedTextFieldDelegate

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
        phoneNumberDidChange()
    }

    func roundedTextFieldDidEndEditing(
        _ textField: RoundedTextField
    ) {
        didEndEditingOnce = true
        phoneNumberDidChange() // activate error checking
    }
}

// MARK: - PhoneCountryCodeSelectorViewDelegate

extension PhoneTextField: PhoneCountryCodeSelectorViewDelegate {

    func phoneCountryCodeSelectorView(
        _ selectorView: PhoneCountryCodeSelectorView,
        didSelectCountryCode countryCode: String
    ) {
        phoneNumberDidChange()
    }
}

#if DEBUG

import SwiftUI

private struct PhoneTextFieldUIViewRepresentable: UIViewRepresentable {

    let defaultPhoneNumber: String

    func makeUIView(context: Context) -> PhoneTextField {
        PhoneTextField(defaultPhoneNumber: defaultPhoneNumber)
    }

    func updateUIView(
        _ phoneTextField: PhoneTextField,
        context: Context
    ) {
        // activate the error-view if needed
        phoneTextField.didEndEditingOnce = true
        phoneTextField.roundedTextField(
            phoneTextField.textField,
            textDidChange: defaultPhoneNumber
        )
    }
}

struct PhoneTextField_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: ""
                ).frame(height: 56)

                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: "4015006000"
                ).frame(height: 56)

                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: "401500600"
                ).frame(height: 90)

                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: "40150060003435"
                ).frame(height: 90)

                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: "+442079460321"
                ).frame(height: 90)

                Spacer()
            }
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
