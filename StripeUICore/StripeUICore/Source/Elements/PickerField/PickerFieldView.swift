//
//  PickerFieldView.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 10/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

protocol PickerFieldViewDelegate: AnyObject {
    func didBeginEditing(_ pickerFieldView: PickerFieldView)
    func didFinish(_ pickerFieldView: PickerFieldView, shouldAutoAdvance: Bool)
    func didCancel(_ pickerFieldView: PickerFieldView)
}

/**
 An input field that looks like TextFieldView but whose input is another view.

 - Note: This view has padding according to `directionalLayoutMargins`.
 For internal SDK use only
 */
@objc(STP_Internal_PickerFieldView)
final class PickerFieldView: UIView {

    // MARK: - Views
    private lazy var toolbar = DoneButtonToolbar(delegate: self, showCancelButton: true, theme: theme)
    private lazy var textField: PickerTextField = {
        let textField = PickerTextField()
        // Input views are not supported on Catalyst
#if !targetEnvironment(macCatalyst)
        textField.inputView = pickerView
#endif
        textField.adjustsFontForContentSizeCategory = true
        textField.font = theme.fonts.subheadline
        textField.inputAccessoryView = toolbar
        textField.delegate = self
        return textField
    }()
    private lazy var floatingPlaceholderTextFieldView: FloatingPlaceholderTextFieldView? = {
        guard let label = label else {
            return nil
        }
        let floatingPlaceholderView = FloatingPlaceholderTextFieldView(textField: textField, theme: theme)
        floatingPlaceholderView.placeholder = label
        return floatingPlaceholderView
    }()
    private lazy var chevronImageView: UIImageView? = {
        guard shouldShowChevron else {
            return nil
        }
        let imageView = UIImageView(image: Image.icon_chevron_down.makeImage().withRenderingMode(.alwaysTemplate))
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.tintColor = theme.colors.textFieldText
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
    private let theme: ElementsUITheme

    // MARK: - Public properties
    var displayText: NSAttributedString? {
        get {
            return textField.attributedText
        }
        set {
            if newValue != textField.attributedPlaceholder {
                invalidateIntrinsicContentSize()
            }
            textField.attributedText = newValue
            // Unfortunate hack for card brand choice to show card brand logos
            // UITextField doesn't render attributed text with text attachments for some reason
            // But it works when setting it's placeholder text
            // https://stackoverflow.com/questions/54804809/cant-add-image-as-nstextattachment-to-uitextfield
            if (newValue?.hasTextAttachment ?? false) && newValue?.length == 1 {
                textField.attributedPlaceholder = newValue
            }
        }
    }

    var displayTextAccessibilityValue: String? {
        get {
            return textField.accessibilityValue
        }
        set {
            textField.accessibilityValue = newValue
        }
    }

    // MARK: - Initializers

    /**
     - Parameter label: The label of this picker
     - Parameter shouldShowChevron: Whether a downward chevron should be displayed in this field
     - Parameter pickerView: A `UIPicker` or `UIDatePicker` view that opens when this field becomes first responder
     - Parameter delegate: Delegate for this view
     - Parameter theme: Theme for the picker field
     */
    init(
        label: String?,
        shouldShowChevron: Bool,
        pickerView: UIView,
        delegate: PickerFieldViewDelegate,
        theme: ElementsUITheme,
        hasPadding: Bool = true
    ) {
        self.label = label
        self.shouldShowChevron = shouldShowChevron
        self.pickerView = pickerView
        self.delegate = delegate
        self.theme = theme
        super.init(frame: .zero)
        addAndPinSubview(hStackView, directionalLayoutMargins: hasPadding ? ElementsUI.contentViewInsets : .zero)
//      On Catalyst, add the picker view as a subview instead of an input view.
        #if targetEnvironment(macCatalyst)
        addAndPinSubview(pickerView, directionalLayoutMargins: ElementsUI.contentViewInsets)
        #endif
        layer.borderColor = theme.colors.border.cgColor
        isUserInteractionEnabled = true
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
            textField.textColor = theme.colors.textFieldText.disabled(!isUserInteractionEnabled)
            if frame.size != .zero {
                textField.layoutIfNeeded()  // Fixes an issue on iOS 15 where setting textField properties causes it to lay out from zero size.
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        layer.borderColor = theme.colors.border.cgColor
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        #if targetEnvironment(macCatalyst)
        // Forward all events within our bounds to the button
        return pickerView
        #else
        // Forward all events within our bounds to the textview
        return textField
        #endif
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
        default:
            break
        }
    }
}

// MARK: - UITextFieldDelegate

extension PickerFieldView: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        UIAccessibility.post(notification: .layoutChanged, argument: pickerView)
        floatingPlaceholderTextFieldView?.updatePlaceholder()
        delegate?.didBeginEditing(self)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        floatingPlaceholderTextFieldView?.updatePlaceholder()
        delegate?.didFinish(self, shouldAutoAdvance: true)
    }
}

// MARK: - DoneButtonToolbarDelegate

extension PickerFieldView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        _ = textField.resignFirstResponder()
    }

    func didTapCancel(_ toolbar: DoneButtonToolbar) {
        delegate?.didCancel(self)
        _ = textField.resignFirstResponder()
    }
}
