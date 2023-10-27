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
}

final class ManualEntryFormView: UIView {

    weak var delegate: ManualEntryFormViewDelegate?

    private lazy var checkView: ManualEntryCheckView = {
        let checkView = ManualEntryCheckView()
        checkView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkView.heightAnchor.constraint(equalToConstant: ManualEntryCheckView.height)
        ])
        return checkView
    }()
    private lazy var textFieldStackView: UIStackView = {
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        let textFieldVerticalStackView = UIStackView(
            arrangedSubviews: [
                routingNumberTextField,
                accountNumberTextField,
                accountNumberConfirmationTextField,
                spacerView,
            ]
        )
        textFieldVerticalStackView.axis = .vertical
        textFieldVerticalStackView.spacing = 16
        return textFieldVerticalStackView
    }()
    private var errorView: ManualEntryErrorView?
    private lazy var routingNumberTextField: ManualEntryTextField = {
        let routingNumberTextField = ManualEntryTextField(
            title: STPLocalizedString(
                "Routing number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the routing number."
            ),
            placeholder: "123456789"
        )
        routingNumberTextField.delegate = self
        routingNumberTextField.textField.addTarget(
            self,
            action: #selector(textFieldTextDidChange),
            for: .editingChanged
        )
        routingNumberTextField.textField.accessibilityIdentifier = "manual_entry_routing_number_text_field"
        return routingNumberTextField
    }()
    private lazy var accountNumberTextField: ManualEntryTextField = {
        let accountNumberTextField = ManualEntryTextField(
            // STPLocalizedString_("Account number", "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the account number."),
            title: "Account number",  // TODO: replace with String.Localized.accountNumber
            placeholder: "000123456789",
            footerText: STPLocalizedString(
                "Please enter a checking account.",
                "A description under a user-input-field that appears when a user is manually entering their bank account information. It the user that the bank account number can be either checkings or savings."
            )
        )
        accountNumberTextField.textField.addTarget(
            self,
            action: #selector(textFieldTextDidChange),
            for: .editingChanged
        )
        accountNumberTextField.delegate = self
        accountNumberTextField.textField.accessibilityIdentifier = "manual_entry_account_number_text_field"
        return accountNumberTextField
    }()
    private lazy var accountNumberConfirmationTextField: ManualEntryTextField = {
        let accountNumberConfirmationTextField = ManualEntryTextField(
            title: STPLocalizedString(
                "Confirm account number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to re-type the account number to confirm it."
            ),
            placeholder: "000123456789"
        )
        accountNumberConfirmationTextField.textField.addTarget(
            self,
            action: #selector(textFieldTextDidChange),
            for: .editingChanged
        )
        accountNumberConfirmationTextField.delegate = self
        accountNumberConfirmationTextField.textField.accessibilityIdentifier = "manual_entry_account_number_confirmation_text_field"
        return accountNumberConfirmationTextField
    }()

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

    init() {
        super.init(frame: .zero)
        let contentVerticalStackView = UIStackView(
            arrangedSubviews: [
                checkView,
                textFieldStackView,
            ]
        )
        contentVerticalStackView.axis = .vertical
        contentVerticalStackView.spacing = 2
        addAndPinSubview(contentVerticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textFieldTextDidChange() {
        delegate?.manualEntryFormViewTextDidChange(self)
        updateTextFieldErrorStates()
    }

    private func updateCheckViewState() {
        checkView.highlightState = .none
        if routingNumberTextField.textField.isFirstResponder {
            checkView.highlightState = .routingNumber
        } else if accountNumberTextField.textField.isFirstResponder
            || accountNumberConfirmationTextField.textField.isFirstResponder
        {
            checkView.highlightState = .accountNumber
        }
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
            let errorView = ManualEntryErrorView(text: text)
            self.errorView = errorView
            textFieldStackView.insertArrangedSubview(errorView, at: 0)
        } else {
            errorView?.removeFromSuperview()
            errorView = nil
        }
    }
}

// MARK: - ManualEntryTextFieldDelegate

extension ManualEntryFormView: ManualEntryTextFieldDelegate {

    func manualEntryTextField(
        _ manualEntryTextField: ManualEntryTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        let currentText = manualEntryTextField.textField.text ?? ""
        guard let currentTextChangeRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: currentTextChangeRange, with: string)

        // don't allow the user to type more characters than possible
        if manualEntryTextField === routingNumberTextField {
            return updatedText.count <= ManualEntryValidator.routingNumberLength
        } else if manualEntryTextField === accountNumberTextField
            || manualEntryTextField === accountNumberConfirmationTextField
        {
            return updatedText.count <= ManualEntryValidator.accountNumberMaxLength
        }

        assertionFailure("we should never have an unhandled case")
        return true
    }

    func manualEntryTextFieldDidBeginEditing(_ textField: ManualEntryTextField) {
        updateCheckViewState()
    }

    func manualEntryTextFieldDidEndEditing(_ manualEntryTextField: ManualEntryTextField) {
        if manualEntryTextField === routingNumberTextField {
            didEndEditingOnceRoutingNumberTextField = true
        } else if manualEntryTextField === accountNumberTextField {
            didEndEditingOnceAccountNumberTextField = true
        } else if manualEntryTextField === accountNumberConfirmationTextField {
            didEndEditingOnceAccountNumberConfirmationTextField = true
        } else {
            assertionFailure("we should always be able to reference a textfield")
        }
        updateTextFieldErrorStates()

        updateCheckViewState()
    }
}
