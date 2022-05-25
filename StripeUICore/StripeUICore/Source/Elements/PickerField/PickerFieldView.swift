//
//  PickerFieldView.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/1/21.
//

import UIKit

protocol PickerFieldViewDelegate: AnyObject {
    func didBeginEditing(_ pickerFieldView: PickerFieldView)
    func didFinish(_ pickerFieldView: PickerFieldView)
}

/**
 An input field that looks like TextFieldView but whose input is another view.
 
 For internal SDK use only
 */
@objc(STP_Internal_PickerFieldView)
final class PickerFieldView: UIView {
    private lazy var toolbar = DoneButtonToolbar(delegate: self)
    lazy var textField: PickerTextField = {
        let textField = PickerTextField()
        textField.inputView = pickerView
        textField.adjustsFontForContentSizeCategory = true
        textField.font = ElementsUITheme.current.fonts.subheadline
        textField.inputAccessoryView = toolbar
        textField.delegate = self
        return textField
    }()
    private var textFieldView: FloatingPlaceholderTextFieldView? = nil

    private let shouldShowChevron: Bool
    private let pickerView: UIView
    weak var delegate: PickerFieldViewDelegate?

    var displayText: String? {
        get {
            return textField.text
        }
        set {
            textField.text = newValue
            textFieldView?.updatePlaceholder(animated: true)
            
            // Note: Calling `layoutIfNeeded` when outside of the window
            // heirarchy causes autolayout errors
            if window != nil {
                textField.layoutIfNeeded() // Fixes an issue on iOS 15 where setting textField properties causes it to lay out from zero size.
            }
        }
    }
    
    var displayTextAccessibilityLabel: String? {
        get {
            return textField.accessibilityLabel
        }
        set {
            textField.accessibilityLabel = newValue
        }
    }

    // MARK: - Initializers

    /**
     - Parameters:
       - label: The label of this picker
       - shouldShowChevron: Whether a downward chevron should be displayed in this field
       - pickerView: A `UIPicker` or `UIDatePicker` view that opens when this field becomes first responder
       - delegate: Delegate for this view
     */
    init(
        label: String?,
        shouldShowChevron: Bool,
        pickerView: UIView,
        delegate: PickerFieldViewDelegate
    ) {
        self.shouldShowChevron = shouldShowChevron
        self.pickerView = pickerView
        self.delegate = delegate
        super.init(frame: .zero)
        layer.borderColor = ElementsUITheme.current.colors.border.cgColor
        
        let chevronImageView: UIImageView? = {
            guard shouldShowChevron else { return nil }
            let imageView = UIImageView(image: Image.icon_chevron_down.makeImage().withRenderingMode(.alwaysTemplate))
            imageView.setContentHuggingPriority(.required, for: .horizontal)
            imageView.tintColor = ElementsUITheme.current.colors.textFieldText
            return imageView
        }()
        if let label = label {
            let floatingPlaceholderView = FloatingPlaceholderTextFieldView(textField: textField)
            floatingPlaceholderView.placeholder = label
            
            let hStack = UIStackView(
                arrangedSubviews: [floatingPlaceholderView, chevronImageView].compactMap { $0 }
            )
            hStack.spacing = 6
            hStack.alignment = .center
            addAndPinSubview(hStack, insets: ElementsUI.contentViewInsets)
            textFieldView = floatingPlaceholderView
        } else {
            let hStack = UIStackView(
                arrangedSubviews:[textField, chevronImageView].compactMap { $0 }
            )
            hStack.alignment = .center
            addAndPinSubview(hStack)
        }

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
        textFieldView?.updatePlaceholder(animated: false)
    }

    override var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                textField.textColor = ElementsUITheme.current.colors.textFieldText
            } else {
                textField.textColor = CompatibleColor.tertiaryLabel
            }
            if frame.size != .zero {
                textField.layoutIfNeeded() // Fixes an issue on iOS 15 where setting textField properties causes it to lay out from zero size.
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = ElementsUITheme.current.colors.border.cgColor
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        // Forward all events within our bounds to the textfield
        return textField
    }
}

// MARK: - EventHandler

extension PickerFieldView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            isUserInteractionEnabled = true
        case .shouldDisableUserInteraction:
            isUserInteractionEnabled = false
        }
    }
}

// MARK: - UITextFieldDelegate

extension PickerFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIAccessibility.post(notification: .layoutChanged, argument: pickerView)
        delegate?.didBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layoutIfNeeded()
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

// MARK: - DoneButtonToolbarDelegate

extension PickerFieldView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        _ = textField.resignFirstResponder()
        delegate?.didFinish(self)
    }
}
