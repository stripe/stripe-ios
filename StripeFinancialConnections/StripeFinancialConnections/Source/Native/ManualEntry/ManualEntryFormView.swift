//
//  ManualEntryFormView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/24/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
import SwiftUI

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
    private lazy var routingNumberTextField: ManualEntryTextField = {
        let routingNumberTextField = ManualEntryTextField(
            title: STPLocalizedString("Routing number", "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the routing number."),
            placeholder: "123456789"
        )
        routingNumberTextField.textField.delegate = self
        routingNumberTextField.textField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        return routingNumberTextField
    }()
    private lazy var accountNumberTextField: ManualEntryTextField = {
        let accountNumberTextField = ManualEntryTextField(
            // STPLocalizedString_("Account number", "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the account number."),
            title: "Account number", // TODO(kgaidis): replace with String.Localized.accountNumber (or fix SDK localized strings)
            placeholder: "000123456789",
            footerText: STPLocalizedString("Your account can be checkings or savings.", "A description under a user-input-field that appears when a user is manually entering their bank account information. It the user that the bank account number can be either checkings or savings.")
        )
        accountNumberTextField.textField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        accountNumberTextField.textField.delegate = self
        return accountNumberTextField
    }()
    private lazy var accountNumberConfirmationTextField: ManualEntryTextField = {
        let accountNumberConfirmationTextField = ManualEntryTextField(
            title: STPLocalizedString("Confirm account number", "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to re-type the account number to confirm it."),
            placeholder: "000123456789"
        )
        accountNumberConfirmationTextField.textField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        accountNumberConfirmationTextField.textField.delegate = self
        return accountNumberConfirmationTextField
    }()
    
    private var didEndEditingOnceRoutingNumberTextField = false
    private var didEndEditingOnceAccountNumberTextField = false
    private var didEndEditingOnceAccountNumberConfirmationTextField = false
    
    var routingAndAccountNumber: (routingNumber: String, accountNumber: String)? {
        guard
            ManualEntryValidator.validateRoutingNumber(routingNumberTextField.text) == nil
                && ManualEntryValidator.validateAccountNumber(accountNumberTextField.text) == nil
                && ManualEntryValidator.validateAccountNumberConfirmation(accountNumberConfirmationTextField.text, accountNumber: accountNumberTextField.text) == nil
        else {
            return nil
        }
        return (routingNumberTextField.text, accountNumberTextField.text)
    }
    
    init() {
        super.init(frame: .zero)
        
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        let contentVerticalStackView = UIStackView(
            arrangedSubviews: [
                checkView,
                CreateTextFieldStackView(
                    arrangedSubviews: [
                        routingNumberTextField,
                        accountNumberTextField,
                        accountNumberConfirmationTextField,
                        spacerView,
                    ]
                ),
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
        } else if accountNumberTextField.textField.isFirstResponder || accountNumberConfirmationTextField.textField.isFirstResponder {
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
}

// MARK: - UITextFieldDelegate

extension ManualEntryFormView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let currentTextChangeRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: currentTextChangeRange, with: string)
        
        // don't allow the user to type more characters than possible
        if textField === routingNumberTextField.textField {
            return updatedText.count <= ManualEntryValidator.routingNumberLength
        } else if textField === accountNumberTextField.textField || textField === accountNumberConfirmationTextField.textField {
            return updatedText.count <= ManualEntryValidator.accountNumberMaxLength
        }
        
        assertionFailure("we should never have an unhandled case")
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateCheckViewState()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField === routingNumberTextField.textField {
            didEndEditingOnceRoutingNumberTextField = true
        } else if textField === accountNumberTextField.textField {
            didEndEditingOnceAccountNumberTextField = true
        } else if textField === accountNumberConfirmationTextField.textField {
            didEndEditingOnceAccountNumberConfirmationTextField = true
        } else {
            assertionFailure("we should always be able to reference a textfield")
        }
        updateTextFieldErrorStates()
        
        updateCheckViewState()
    }
}

// MARK: - Helpers

private func CreateTextFieldStackView(arrangedSubviews: [UIView]) -> UIView {
    let textFieldVerticalStackView = UIStackView(arrangedSubviews: arrangedSubviews)
    textFieldVerticalStackView.axis = .vertical
    textFieldVerticalStackView.spacing = 24
    return textFieldVerticalStackView
}
