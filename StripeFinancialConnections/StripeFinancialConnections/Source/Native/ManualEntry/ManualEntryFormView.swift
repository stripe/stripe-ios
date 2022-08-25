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
            title: "Routing number",
            placeholder: "123456789"
        )
        routingNumberTextField.textField.delegate = self
        routingNumberTextField.textField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        return routingNumberTextField
    }()
    private lazy var accountNumberTextField: ManualEntryTextField = {
        let accountNumberTextField = ManualEntryTextField(
            title: "Account number",
            placeholder: "000123456789",
            footerText: "Your account can be checkings or savings."
        )
        accountNumberTextField.textField.addTarget(self, action: #selector(textFieldTextDidChange), for: .editingChanged)
        accountNumberTextField.textField.delegate = self
        return accountNumberTextField
    }()
    private lazy var accountNumberConfirmationTextField: ManualEntryTextField = {
        let accountNumberConfirmationTextField = ManualEntryTextField(
            title: "Confirm account number",
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
        guard didEndEditingOnceAccountNumberTextField && didEndEditingOnceAccountNumberTextField && didEndEditingOnceAccountNumberConfirmationTextField else {
            // user did not finish entering all fields; we are making an assumption here
            // that here that keyboard must be dismissed for user to press "Continue"
            return nil
        }
        guard routingNumberTextField.errorText != nil || accountNumberTextField.errorText != nil || accountNumberConfirmationTextField.errorText != nil else {
            return nil // there's a pending error to resolve
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
            if routingNumberTextField.text.isEmpty {
                routingNumberTextField.errorText = "Routing number is required."
            } else {
                routingNumberTextField.errorText = nil
            }
        }
        
        if didEndEditingOnceAccountNumberTextField {
            if accountNumberTextField.text.isEmpty {
                accountNumberTextField.errorText = "Account number is required."
            } else {
                accountNumberTextField.errorText = nil
            }
        }
        
        if didEndEditingOnceAccountNumberConfirmationTextField {
            if accountNumberConfirmationTextField.text.isEmpty {
                accountNumberConfirmationTextField.errorText = "Confirm the account number."
            } else {
                accountNumberConfirmationTextField.errorText = nil
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension ManualEntryFormView: UITextFieldDelegate {
    
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
