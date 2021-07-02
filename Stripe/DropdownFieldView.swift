//
//  DropdownView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

// MARK: - DropdownFieldView

/**
 An input field that looks like TextFieldView but whose input is a UIPickerView.
 
 - Note: Defaults to the first item in the `items` list.
 */
class DropdownFieldView: UIView {
    lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    lazy var textField: DropdownTextField = {
        let textField = DropdownTextField()
        textField.inputView = pickerView
        return textField
    }()
    let items: [String]
    var selectedRow: Int = 0
    
    init(items: [String], accessibilityLabel: String) {
        self.items = items
        super.init(frame: .zero)
        addAndPinSubview(textField)
        pickerView.selectRow(0, inComponent: 0, animated: false)
        textField.text = items.first
        textField.accessibilityLabel = accessibilityLabel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        // Be the same height as a TextFieldView
        return CGSize(width: textField.intrinsicContentSize.width, height: TextFieldView.height)
    }
}

// MARK: UIPickerViewDelegate

extension DropdownFieldView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedRow = row
        textField.text = items[row]
    }
}

extension DropdownFieldView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }
}

// MARK: - DropdownTextField

/**
 A subclass of `UITextField` suitable for use with a `UIPickerView` as its input view.
 
 It disables manual text entry and adds a 'Done' button to the input view.
 */
class DropdownTextField: UITextField {
    lazy var toolbar: UIToolbar = {
        // Initializing w/ an arbitrary frame stops autolayout from complaining on the first layout pass
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(didTapDone)
        )
        doneButton.accessibilityLabel = UIButton.doneButtonTitle
        toolbar.setItems([doneButton], animated: false)
        toolbar.sizeToFit()
        toolbar.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return toolbar
    }()
    
    // MARK: Initializers
    
    init() {
        super.init(frame: .zero)
        adjustsFontForContentSizeCategory = true
        font = .preferredFont(forTextStyle: .body)
        inputAccessoryView = toolbar
        rightView = UIImageView(image: Image.icon_chevron_down.makeImage())
        rightViewMode = .always
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides

    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }
    
    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    // MARK: Internal Methods

    @objc func didTapDone() {
        _ = resignFirstResponder()
    }
}

// MARK: UITextFieldDelegate

extension DropdownTextField: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return false
    }
}
