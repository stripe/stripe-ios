//
//  ManualEntryFormView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/24/22.
//

import Foundation
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

protocol ManualEntryFormViewDelegate: AnyObject {
    func manualEntryFormViewTextDidChange(_ view: ManualEntryFormView)
    func manualEntryFormViewShouldSubmit(_ view: ManualEntryFormView)
}

final class ManualEntryFormView: UIView {

    enum TestModeValues {
        static let routingNumber = "110000000"
        static let accountNumber = "000123456789"
    }

    weak var delegate: ManualEntryFormViewDelegate?
    private lazy var textFieldStackView: UIStackView = {
        let textFieldVerticalStackView = UIStackView(
            arrangedSubviews: [
                routingNumberTextField,
                accountNumberTextField,
                accountNumberConfirmationTextField,
            ]
        )
        textFieldVerticalStackView.axis = .vertical
        textFieldVerticalStackView.spacing = 16
        return textFieldVerticalStackView
    }()
    private var errorView: UIView?
    private lazy var routingNumberTextField: RoundedTextField = {
        let routingNumberTextField = RoundedTextField(
            placeholder: STPLocalizedString(
                "Routing number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the routing number."
            ),
            showDoneToolbar: true,
            appearance: appearance
        )
        routingNumberTextField.textField.keyboardType = .numberPad
        routingNumberTextField.delegate = self
        routingNumberTextField.textField.accessibilityIdentifier = "manual_entry_routing_number_text_field"
        return routingNumberTextField
    }()
    private lazy var accountNumberTextField: RoundedTextField = {
        let accountNumberTextField = RoundedTextField(
            placeholder: STPLocalizedString(
                "Account number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the account number."
            ),
            showDoneToolbar: true,
            appearance: appearance
        )
        accountNumberTextField.textField.keyboardType = .numberPad
        accountNumberTextField.delegate = self
        accountNumberTextField.textField.accessibilityIdentifier = "manual_entry_account_number_text_field"
        return accountNumberTextField
    }()
    private lazy var accountNumberConfirmationTextField: RoundedTextField = {
        let accountNumberConfirmationTextField = RoundedTextField(
            placeholder: STPLocalizedString(
                "Confirm account number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to re-type the account number to confirm it."
            ),
            showDoneToolbar: true,
            appearance: appearance
        )
        accountNumberConfirmationTextField.textField.keyboardType = .numberPad
        accountNumberConfirmationTextField.delegate = self
        accountNumberConfirmationTextField.textField.accessibilityIdentifier = "manual_entry_account_number_confirmation_text_field"
        return accountNumberConfirmationTextField
    }()

    private let appearance: FinancialConnectionsAppearance
    private var didEndEditingOnceRoutingNumberTextField = false
    private var didEndEditingOnceAccountNumberTextField = false
    private var didEndEditingOnceAccountNumberConfirmationTextField = false

    var routingAndAccountNumber: (routingNumber: String, accountNumber: String)? {
        guard
            ManualEntryValidator.validateRoutingNumber(routingNumberTextField.text) == nil
                && ManualEntryValidator.validateAccountNumber(accountNumberTextField.text) == nil
                && ManualEntryValidator.validateAccountNumberConfirmation(
                    accountNumberConfirmationTextField.text,
                    accountNumber: accountNumberTextField.text
                ) == nil
        else {
            return nil
        }
        return (routingNumberTextField.text, accountNumberTextField.text)
    }

    init(isTestMode: Bool, appearance: FinancialConnectionsAppearance) {
        self.appearance = appearance
        super.init(frame: .zero)

        let contentVerticalStackView = UIStackView()

        if isTestMode {
            let testModeBannerView = TestModeAutofillBannerView(
                context: .account,
                appearance: appearance,
                didTapAutofill: applyTestModeValues
            )
            contentVerticalStackView.addArrangedSubview(testModeBannerView)
        }

        contentVerticalStackView.addArrangedSubview(textFieldStackView)

        contentVerticalStackView.axis = .vertical
        contentVerticalStackView.spacing = 16
        addAndPinSubview(contentVerticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textFieldTextDidChange() {
        delegate?.manualEntryFormViewTextDidChange(self)
        updateTextFieldErrorStates()
    }

    private func updateTextFieldErrorStates() {
        // we only show errors if user has previously ended editing the field

        if didEndEditingOnceRoutingNumberTextField {
            routingNumberTextField.errorText = ManualEntryValidator.validateRoutingNumber(routingNumberTextField.text)
        }

        if didEndEditingOnceAccountNumberTextField {
            accountNumberTextField.errorText = ManualEntryValidator.validateAccountNumber(accountNumberTextField.text)
        }

        if didEndEditingOnceAccountNumberConfirmationTextField {
            accountNumberConfirmationTextField.errorText = ManualEntryValidator.validateAccountNumberConfirmation(
                accountNumberConfirmationTextField.text,
                accountNumber: accountNumberTextField.text
            )
        }
    }

    func setError(text: String?) {
        if let text = text {
            let errorLabel = AttributedTextView(
                font: .label(.medium),
                boldFont: .label(.mediumEmphasized),
                linkFont: .label(.medium),
                textColor: FinancialConnectionsAppearance.Colors.textCritical,
                linkColor: FinancialConnectionsAppearance.Colors.textCritical,
                alignment: .center
            )
            errorLabel.setText(text)
            let paddingStackView = UIStackView(
                arrangedSubviews: [
                    errorLabel
                ]
            )
            paddingStackView.isLayoutMarginsRelativeArrangement = true
            paddingStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 8,
                leading: 0,
                bottom: 8,
                trailing: 0
            )
            textFieldStackView.addArrangedSubview(paddingStackView)
            self.errorView = paddingStackView
        } else {
            errorView?.removeFromSuperview()
            errorView = nil
        }
    }

    private func applyTestModeValues() {
        routingNumberTextField.text = TestModeValues.routingNumber
        accountNumberTextField.text = TestModeValues.accountNumber
        accountNumberConfirmationTextField.text = TestModeValues.accountNumber

        delegate?.manualEntryFormViewShouldSubmit(self)
    }
}

// MARK: - RoundedTextFieldDelegate

extension ManualEntryFormView: RoundedTextFieldDelegate {

    func roundedTextField(
        _ textField: RoundedTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = textField.textField.text ?? ""
        guard let currentTextChangeRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: currentTextChangeRange, with: string)

        // don't allow the user to type more characters than possible
        if textField === routingNumberTextField {
            return updatedText.count <= ManualEntryValidator.routingNumberLength
        } else if textField === accountNumberTextField
            || textField === accountNumberConfirmationTextField
        {
            return updatedText.count <= ManualEntryValidator.accountNumberMaxLength
        }

        assertionFailure("we should never have an unhandled case")
        return true
    }

    func roundedTextField(_ textField: RoundedTextField, textDidChange text: String) {
        textFieldTextDidChange()
    }

    func roundedTextFieldUserDidPressReturnKey(_ textField: RoundedTextField) {
        // no-op
    }

    func roundedTextFieldDidEndEditing(_ textField: RoundedTextField) {
        if textField === routingNumberTextField {
            didEndEditingOnceRoutingNumberTextField = true
        } else if textField === accountNumberTextField {
            didEndEditingOnceAccountNumberTextField = true
        } else if textField === accountNumberConfirmationTextField {
            didEndEditingOnceAccountNumberConfirmationTextField = true
        } else {
            assertionFailure("we should always be able to reference a textfield")
        }
        updateTextFieldErrorStates()
    }
}
