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
    private lazy var routingNumberTextField: ManualEntryTextField = {
        let routingNumberTextField = ManualEntryTextField(
            placeholder: STPLocalizedString(
                "Routing number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the routing number."
            )
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
            placeholder: STPLocalizedString("Account number", "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to type the account number.")
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
            placeholder: STPLocalizedString(
                "Confirm account number",
                "The title of a user-input-field that appears when a user is manually entering their bank account information. It instructs user to re-type the account number to confirm it."
            )
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
                textColor: .textFeedbackCritical,
                linkColor: .textFeedbackCritical,
                alignCenter: true
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
    }
}
