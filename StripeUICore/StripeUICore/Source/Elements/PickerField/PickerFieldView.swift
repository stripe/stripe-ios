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
 
 - Note: This view has padding according to `directionalLayoutMargins`.
 For internal SDK use only
 */
@objc(STP_Internal_PickerFieldView)
final class PickerFieldView: UIView {
    // MARK: - Views
    private lazy var toolbar = DoneButtonToolbar(delegate: self)
    private lazy var textField: PickerTextField = {
        let textField = PickerTextField()
        textField.inputView = pickerView
        textField.adjustsFontForContentSizeCategory = true
        textField.font = ElementsUITheme.current.fonts.subheadline
        textField.inputAccessoryView = toolbar
        textField.delegate = self
        return textField
    }()
    private lazy var floatingPlaceholderTextFieldView: FloatingPlaceholderTextFieldView? = {
        guard let label = label else {
            return nil
        }
        let floatingPlaceholderView = FloatingPlaceholderTextFieldView(textField: textField)
        floatingPlaceholderView.placeholder = label
        return floatingPlaceholderView
    }()
    private lazy var chevronImageView: UIImageView? = {
        guard shouldShowChevron else {
            return nil
        }
        let imageView = UIImageView(image: Image.icon_chevron_down.makeImage().withRenderingMode(.alwaysTemplate))
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.tintColor = ElementsUITheme.current.colors.textFieldText
        return imageView
    }()
    private lazy var hStackView: UIStackView = {
        let hStackView = UIStackView(
            arrangedSubviews: [floatingPlaceholderTextFieldView ?? textField, chevronImageView].compactMap { $0 }
        )
        hStackView.alignment = .center
        hStackView.spacing = 6
        return hStackView
    }()
    private let pickerView: UIView
    
    // MARK: - Other private properties
    private let label: String?
    private let shouldShowChevron: Bool
    private weak var delegate: PickerFieldViewDelegate?
    
    // MARK: - Public properties
    var displayText: String? {
        get {
            return textField.text
        }
        set {
            if newValue != textField.text {
                invalidateIntrinsicContentSize()
            }
            textField.text = newValue
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
     - Parameter label: The label of this picker
     - Parameter shouldShowChevron: Whether a downward chevron should be displayed in this field
     - Parameter pickerView: A `UIPicker` or `UIDatePicker` view that opens when this field becomes first responder
     - Parameter delegate: Delegate for this view
     */
    init(
        label: String?,
        shouldShowChevron: Bool,
        pickerView: UIView,
        delegate: PickerFieldViewDelegate
    ) {
        self.label = label
        self.shouldShowChevron = shouldShowChevron
        self.pickerView = pickerView
        self.delegate = delegate
        super.init(frame: .zero)
        addAndPinSubview(hStackView, directionalLayoutMargins: ElementsUI.contentViewInsets)
        layer.borderColor = ElementsUITheme.current.colors.border.cgColor
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
        floatingPlaceholderTextFieldView?.updatePlaceholder(animated: false)
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
    
    override var intrinsicContentSize: CGSize {
        // I'm implementing this to disambiguate layout of a horizontal stack view containing this view
        let hStackViewSize = hStackView.systemLayoutSizeFitting(.zero)
        return CGSize(
            width: hStackViewSize.width + directionalLayoutMargins.leading + directionalLayoutMargins.trailing,
            height: hStackViewSize.height + directionalLayoutMargins.top + directionalLayoutMargins.bottom
        )
    }
    
    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            return true
        }
        return textField.becomeFirstResponder()
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
