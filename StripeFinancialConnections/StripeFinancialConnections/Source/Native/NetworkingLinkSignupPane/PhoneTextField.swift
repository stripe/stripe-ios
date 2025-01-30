//
//  PhoneTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeCore
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
            placeholder: STPLocalizedString("Phone number", "The title of a user-input-field that appears when a user is signing up to Link (a payment service). It instructs user to type a phone number."),
            showDoneToolbar: true,
            appearance: appearance
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
        textField.textField.accessibilityIdentifier = "phone_text_field"
        return textField
    }()
    private let countryCodeSelectorView: PhoneCountryCodeSelectorView
    private let appearance: FinancialConnectionsAppearance
    // we will only start validating as user
    // types once editing ends
    fileprivate var didEndEditingOnce = false

    var text: String {
        get {
            textField.text
        }
        set {
            textField.text = newValue
            phoneNumberDidChange()
        }
    }
    var phoneNumber: PhoneNumber? {
        return PhoneNumber(number: text, countryCode: countryCodeSelectorView.selectedCountryCode)
    }
    var isPhoneNumberValid: Bool {
        if text.isEmpty {
            // empty phone number
            return false
        } else if let phoneNumber {
            return phoneNumber.isComplete
        } else {
            // Assume user has entered a format or for a region the SDK doesn't know about.
            // Return valid as long as it's non-empty and let the server decide.
            return true
        }
    }

    weak var delegate: PhoneTextFieldDelegate?

    init(defaultPhoneNumber: String?, appearance: FinancialConnectionsAppearance) {
        var defaultPhoneNumber = defaultPhoneNumber
        var defaultCountryCode: String?
        if let _defaultPhoneNumber = defaultPhoneNumber, let e164PhoneNumber = PhoneNumber.fromE164(_defaultPhoneNumber) {
            defaultPhoneNumber = e164PhoneNumber.number
            defaultCountryCode = e164PhoneNumber.countryCode
        }
        self.countryCodeSelectorView = PhoneCountryCodeSelectorView(
            defaultCountryCode: defaultCountryCode,
            appearance: appearance
        )
        self.appearance = appearance
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
        // if we notice that `text` starts with a prefix
        // (ex. due to autofill, or copy-paste), then we will extract
        // the prefix
        if
            // we noticed that user started input with a prefix
            text.hasPrefix("+"),
            let e164PhoneNumber = PhoneNumber.fromE164(
                // `fromE164` only accepts a format like "+14005006000"
                // so remove everything except digits and "+"
                text.stp_stringByRemovingCharacters(
                    from: CharacterSet.stp_asciiDigit.union(
                        CharacterSet(charactersIn: "+")
                    ).inverted
                )
            )
        {
            // (IMPORTANT!) this will call `phoneNumberDidChange` again
            text = e164PhoneNumber
                .number
                // the "+" should already be removed at this point but
                // we add this extra code as defensive programming
                //
                // it ensures that we will not enter a infinite
                // loop because to enter this code the text needs
                // to start with a "+" (`text.hasPrefix("+")`)
                .stp_stringByRemovingCharacters(
                    from: CharacterSet(charactersIn: "+")
                )

            // (IMPORTANT!) this will call `phoneNumberDidChange` again
            //
            // its important that it comes after setting `text`
            // because otherwise there will be an infinite loop
            countryCodeSelectorView.selectCountryCode(e164PhoneNumber.countryCode)

            // Setting `text` will cause this function to be
            // called again so its safe to return
            return
        }

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
                    textField.errorText = STPLocalizedString("Your mobile phone number is incomplete.", "An error message that instructs the user to keep typing their phone number in a user-input field.")
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

    func roundedTextFieldUserDidPressReturnKey(_ textField: RoundedTextField) {
        // no-op
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
        PhoneTextField(defaultPhoneNumber: defaultPhoneNumber, appearance: .stripe)
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
                ).frame(height: 56)

                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: "40150060003435"
                ).frame(height: 56)

                PhoneTextFieldUIViewRepresentable(
                    defaultPhoneNumber: "+442079460321"
                ).frame(height: 56)

                Spacer()
            }
            .padding()
            .background(Color(FinancialConnectionsAppearance.Colors.background))
        }
    }
}

#endif
