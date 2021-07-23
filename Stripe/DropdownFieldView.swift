//
//  DropdownView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 6/17/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

protocol DropdownFieldViewDelegate: AnyObject {
    func didFinish(_ dropDownFieldView: DropdownFieldView)
}

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
    lazy var textField: DropdownTextField = {
        let textField = DropdownTextField()
        textField.inputView = pickerView
        textField.adjustsFontForContentSizeCategory = true
        textField.font = .preferredFont(forTextStyle: .body)
        textField.inputAccessoryView = toolbar
        textField.delegate = self
        return textField
    }()
    lazy var textFieldView: FloatingPlaceholderTextFieldView = {
        return FloatingPlaceholderTextFieldView(
            textField: textField,
            image: Image.icon_chevron_down.makeImage()
        )
    }()
    let items: [String]
    var selectedRow: Int = 0
    weak var delegate: DropdownFieldViewDelegate?
    
    // MARK: - Initializers
    
    init(items: [String], defaultIndex: Int, label: String, delegate: DropdownFieldViewDelegate) {
        self.items = items
        self.delegate = delegate
        super.init(frame: .zero)
        layer.borderColor = PaymentSheetUI.fieldBorderColor.cgColor
        
        addAndPinSubview(textFieldView)
        textFieldView.placeholder.text = label
        // Default to defaultIndex
        pickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
        textField.text = items[defaultIndex]
        selectedRow = defaultIndex
        defer {
            isUserInteractionEnabled = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        textFieldView.updatePlaceholder(animated: false)
    }
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                textField.textColor = CompatibleColor.label
            } else {
                textField.textColor = CompatibleColor.tertiaryLabel
            }
        }
    }

    // MARK: Internal Methods

    @objc func didTapDone() {
        _ = textField.resignFirstResponder()
        delegate?.didFinish(self)
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

// MARK: - EventHandler

extension DropdownFieldView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            isUserInteractionEnabled = true
        case .shouldDisableUserInteraction:
            isUserInteractionEnabled = false
        }
    }
}

// MARK: UITextFieldDelegate

extension DropdownFieldView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didFinish(self)
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return false
    }
}
