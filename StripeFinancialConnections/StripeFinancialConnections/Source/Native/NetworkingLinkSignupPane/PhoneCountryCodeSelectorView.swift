//
//  PhoneCountryCodeSelectorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol PhoneCountryCodeSelectorViewDelegate: AnyObject {
    func phoneCountryCodeSelectorView(
        _ selectorView: PhoneCountryCodeSelectorView,
        didSelectCountryCode countryCode: String
    )
}

final class PhoneCountryCodeSelectorView: UIView {

    private lazy var flagLabel: AttributedLabel = {
        let flagLabel = AttributedLabel(
            font: .label(.large),
            textColor: FinancialConnectionsAppearance.Colors.textDefault
        )
        return flagLabel
    }()
    private lazy var countryCodeLabel: AttributedLabel = {
        let flagLabel = AttributedLabel(
            font: .label(.large),
            textColor: FinancialConnectionsAppearance.Colors.textDefault
        )
        return flagLabel
    }()
    // to show the `pickerView` as a keyboard, we need an
    // "invisible" UITextField for the user to tap on
    private lazy var invisbleTextField: UITextField = {
        let textField = UnselectableTextField()
        textField.autocorrectionType = .no
        textField.tintColor = .clear
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.inputView = pickerView
        textField.inputAccessoryView = keyboardToolbar
        return textField
    }()
    private lazy var keyboardToolbar: DoneButtonToolbar = {
        var theme: ElementsAppearance = .default
        theme.colors = {
            var colors = ElementsAppearance.Color()
            colors.primary = appearance.colors.primary
            colors.secondaryText = FinancialConnectionsAppearance.Colors.textSubdued
            return colors
        }()
        let keyboardToolbar = DoneButtonToolbar(
            delegate: self,
            showCancelButton: false,
            theme: theme
        )
        return keyboardToolbar
    }()
    private let pickerView: PhoneCountryCodePickerView
    private let appearance: FinancialConnectionsAppearance
    var selectedCountryCode: String {
        return pickerView.selectedCountryCode
    }

    weak var delegate: PhoneCountryCodeSelectorViewDelegate?

    init(defaultCountryCode: String?, appearance: FinancialConnectionsAppearance) {
        self.pickerView = PhoneCountryCodePickerView(defaultCountryCode: defaultCountryCode)
        self.appearance = appearance
        super.init(frame: .zero)
        pickerView.delegate = self

        backgroundColor = FinancialConnectionsAppearance.Colors.backgroundSecondary
        layer.cornerRadius = 8
        clipsToBounds = true
        accessibilityIdentifier = "phone_country_code_selector"

        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                flagLabel,
                countryCodeLabel,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 8
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 12,
            trailing: 12
        )
        addAndPinSubview(horizontalStackView)
        addAndPinSubview(invisbleTextField)

        // this will update the view based off whatever the
        // default is in the picker view
        updateLabelsBasedOffSelectedCountryCode()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func endEditing(_ force: Bool) -> Bool {
        return invisbleTextField.endEditing(force)
    }

    func selectCountryCode(_ countryCode: String) {
        // this will fire `PhoneCountryCodePickerViewDelegate`
        pickerView.selectCountryCode(countryCode)
    }

    private func updateLabelsBasedOffSelectedCountryCode() {
        flagLabel.setText(String.countryFlagEmoji(for: selectedCountryCode) ?? "🇺🇸")
        countryCodeLabel.setText(PhoneNumber.Metadata.metadata(for: selectedCountryCode)?.prefix ?? "")
    }
}

// MARK: - PhoneCountryCodePickerViewDelegate

extension PhoneCountryCodeSelectorView: PhoneCountryCodePickerViewDelegate {

    func phoneCountryCodePickerView(
        _ pickerView: PhoneCountryCodePickerView,
        didSelectCountryCode countryCode: String
    ) {
        updateLabelsBasedOffSelectedCountryCode()
        delegate?.phoneCountryCodeSelectorView(self, didSelectCountryCode: countryCode)
    }
}

// MARK: - DoneButtonToolbarDelegate

extension PhoneCountryCodeSelectorView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        invisbleTextField.endEditing(true)
    }
}

private class UnselectableTextField: UITextField {
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }

    override func canPerformAction(
        _ action: Selector,
        withSender sender: Any?
    ) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
