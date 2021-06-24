//
//  STPGenericInputPickerField.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 2/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

protocol STPGenericInputPickerFieldDataSource {
    func numberOfRows() -> Int
    func inputPickerField(_ pickerField: STPGenericInputPickerField, titleForRow row: Int)
        -> String?
    func inputPickerField(_ pickerField: STPGenericInputPickerField, inputValueForRow row: Int)
        -> String?
}

class STPGenericInputPickerField: STPInputTextField {
    /// Basic validator that sets `validationState` to `.valid` if there's an inputValue
    class Validator: STPInputTextFieldValidator {
        override var inputValue: String? {
            didSet {
                validationState =
                    (inputValue?.isEmpty != false)
                    ? .incomplete(description: nil) : .valid(message: nil)
            }
        }
    }

    /**
     Formatter specific to `STPGenericInputPickerField`.

     Contains overrides to `UITextFieldDelegate` that ensure the textfield's text can't be
     selected and the placeholder text displays correctly for a dropdown/picker style input.
     */
    class Formatter: STPInputTextFieldFormatter {
        
        override func isAllowedInput(_ input: String, to string: String, at range: NSRange) -> Bool {
            return false // no typing allowed
        }
        
        // See extension for rest of implementation
    }

    fileprivate let wrappedDataSource: DataSourceWrapper
    let pickerView = UIPickerView()

    var dataSource: STPGenericInputPickerFieldDataSource {
        return wrappedDataSource.inputDataSource
    }

    init(
        dataSource: STPGenericInputPickerFieldDataSource,
        formatter: STPGenericInputPickerField.Formatter = .init(),
        validator: STPInputTextFieldValidator = Validator()
    ) {
        self.wrappedDataSource = DataSourceWrapper(inputDataSource: dataSource)
        super.init(formatter: formatter, validator: validator)
    }

    @objc public override var accessibilityAttributedValue: NSAttributedString? {
        get {
            return nil
        }
        set {}
    }


    @objc public override var accessibilityAttributedLabel: NSAttributedString? {
        get {
            return nil
        }
        set {}
    }

    required init(formatter: STPInputTextFieldFormatter, validator: STPInputTextFieldValidator) {

        fatalError("Use init(dataSource:formatter:validator:) instead")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupSubviews() {
        super.setupSubviews()

        pickerView.delegate = self
        pickerView.dataSource = wrappedDataSource
        inputView = pickerView

        let toolbar = UIToolbar()
        let doneButton = UIBarButtonItem(title: UIButton.doneButtonTitle, style: .plain,
                                         target: self, action: #selector(self.didTapDone))
        toolbar.setItems([doneButton], animated: false)
        toolbar.sizeToFit()
        toolbar.setContentHuggingPriority(.defaultLow, for: .horizontal)
        inputAccessoryView = toolbar

        rightView = UIImageView(image: Image.icon_chevron_down.makeImage())
        rightViewMode = .always

        // Prevents selection from flashing if the user double-taps on a word
        tintColor = .clear

        // Prevents text from being highlighted red if the user double-taps a word the spell checker doesn't recognize
        autocorrectionType = .no
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        // hide the caret
        return .zero
    }

    @objc func didTapDone() {
        _ = resignFirstResponder()
    }

    override func textDidChange() {
        /*
         NOTE(mludowise): There's probably a more elegant solution than
         overriding this method, but this fixes a transcient bug where the
         validator's inputValue would temprorily get set to the display text
         (e.g. "United States") instead of value (e.g. "US") causing the field
         to display as invalid and postal code to sometimes not display when a
         valid country was selected.

         Override this method from `STPInputTextField` because...
         1. We don't want to override validator.input with the display text.
         2. The logic in `STPInputTextField` handles validation and formatting
            for cases when the user is typing in text into the text field, which
            we don't allow in this case since the value is determined from our
            data source.
         */
    }
}

// MARK: - UIPickerViewDelegate

/// :nodoc:
extension STPGenericInputPickerField: UIPickerViewDelegate {
    func pickerView(
        _ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int
    ) -> NSAttributedString? {
        guard let title = dataSource.inputPickerField(self, titleForRow: row) else {
            return nil
        }
        // Make sure the picker font matches our standard input font
        return NSAttributedString(
            string: title, attributes: [.font: font ?? UIFont.preferredFont(forTextStyle: .body)])
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        text = dataSource.inputPickerField(self, titleForRow: row)
        validator.inputValue = dataSource.inputPickerField(self, inputValueForRow: row)

        // Hide the placeholder so it behaves as though the placeholder is
        // replaced with the selected value rather than displaying as a title
        // label above the text.
        placeholder = nil
    }
}

// MARK: - Formatter

extension STPGenericInputPickerField.Formatter {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard let inputField = textField as? STPGenericInputPickerField else {
            return
        }

        // If this is the first time the picker displays, we need to display the
        // current selection by manually calling the delegate method
        inputField.pickerView(
            inputField.pickerView, didSelectRow: inputField.pickerView.selectedRow(inComponent: 0),
            inComponent: 0)
        UIAccessibility.post(notification: .layoutChanged, argument: inputField.pickerView)
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        // Disable text selection
        textField.selectedTextRange = textField.textRange(
            from: textField.beginningOfDocument,
            to: textField.beginningOfDocument
        )
    }
}

/// Wraps `STPGenericInputPickerFieldDataSource` into `UIPickerViewDataSource`
private class DataSourceWrapper: NSObject, UIPickerViewDataSource {
    let inputDataSource: STPGenericInputPickerFieldDataSource

    init(inputDataSource: STPGenericInputPickerFieldDataSource) {
        self.inputDataSource = inputDataSource
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return inputDataSource.numberOfRows()
    }
}
