//
//  TextFieldView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 6/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol TextFieldViewDelegate: AnyObject {
    func textFieldViewDidUpdate(view: TextFieldView)
    func textFieldViewContinueToNextField(view: TextFieldView)
}

/**
 A text input field view with a floating placeholder and images.
 - Seealso: `TextFieldElement.ViewModel`
 
 For internal SDK use only
 */
@objc(STP_Internal_TextFieldView)
class TextFieldView: UIView {
    weak var delegate: TextFieldViewDelegate?
    private lazy var toolbar = DoneButtonToolbar(delegate: self, theme: viewModel.theme)

    lazy var transparentMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = viewModel.theme.colors.componentBackground.translucentMaskColor
        return view
    }()

    var text: String {
        return textField.text ?? ""
    }
    var isEditing: Bool {
        return textField.isEditing
    }
    override var isUserInteractionEnabled: Bool {
        didSet {
            textField.isUserInteractionEnabled = isUserInteractionEnabled
            updateUI(with: viewModel)
        }
    }

    var didReceiveAutofill = false

    // MARK: - Views

    // A text field that remembers if it wanted to become the first responder, but failed to do so.
    // We'll track this for the very specific situation where we're trying to swap out a text field for a replacement
    // immediately after the user tapped this one.
    class STPTextFieldThatRemembersWantingToBecomeFirstResponder: UITextField {
        private(set) var wantedToBecomeFirstResponder = false

        override func becomeFirstResponder() -> Bool {
            if canBecomeFirstResponder {
                wantedToBecomeFirstResponder = true
            }
            let didBecomeFirstResponder = super.becomeFirstResponder()
            if didBecomeFirstResponder {
                // It succeeded, so now it can forget!
                wantedToBecomeFirstResponder = false
            }
            return didBecomeFirstResponder
        }
    }

    private(set) lazy var textField: STPTextFieldThatRemembersWantingToBecomeFirstResponder = {
        let textField = STPTextFieldThatRemembersWantingToBecomeFirstResponder()
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.font = viewModel.theme.fonts.subheadline
        return textField
    }()
    private lazy var textFieldView: FloatingPlaceholderTextFieldView = {
        return FloatingPlaceholderTextFieldView(textField: textField, theme: viewModel.theme)
    }()

    let accessoryContainerView = UIView()

    /// This could contain the logos of networks, banks, etc.
    var accessoryView: UIView? {
        didSet {
            // For some reason, the stackview chooses to stretch accessoryContainerView if its
            // content is nil instead of the text field, so we hide it.
            accessoryContainerView.setHiddenIfNecessary(accessoryView == nil)

            guard oldValue != accessoryView else {
                return
            }
            oldValue?.removeFromSuperview()

            if let accessoryView = accessoryView as? PickerFieldView {
                // Hack, disable the ability for the picker to take focus while it's being added as a sub view
                // Occasionally the OS will attempt to call `becomeFirstResponder` on it, causing it to take focus
                accessoryView.setCanBecomeFirstResponder(false)
                accessoryContainerView.addAndPinSubview(accessoryView)
                accessoryView.setContentHuggingPriority(.required, for: .horizontal)
                // Don't have trailing padding when showing a picker view in the accessory view
                hStack.updateTrailingAnchor(constant: 0)
                accessoryView.setCanBecomeFirstResponder(true)
            } else if let accessoryView = accessoryView {
                accessoryContainerView.addAndPinSubview(accessoryView)
                accessoryView.setContentHuggingPriority(.required, for: .horizontal)
                hStack.updateTrailingAnchor(constant: -ElementsUI.contentViewInsets.trailing)
            }
        }
    }

    lazy var errorIconView: UIImageView = {
        let imageView = UIImageView(image: Image.icon_error.makeImage(template: true))
        imageView.tintColor = viewModel.theme.colors.danger
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    lazy var clearButton: UIButton = {
        let button = UIButton(type: .custom)
        button.tintColor = viewModel.theme.colors.placeholderText
        button.setImage(Image.icon_clear.makeImage(template: true), for: .normal)
        button.isHidden = true
        button.addTarget(self, action: #selector(clearText), for: .touchUpInside)

        return button
    }()
    private var viewModel: TextFieldElement.ViewModel
    private var hStack = UIStackView()

    // MARK: - Initializers

    init(viewModel: TextFieldElement.ViewModel, delegate: TextFieldViewDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        isAccessibilityElement = false // false b/c we use `accessibilityElements`
        installConstraints()
        updateUI(with: viewModel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        // We override hitTest to forward all events within our bounds to the textfield
        // ...except for these subviews:
        for interactableSubview in [clearButton, accessoryView].compactMap({ $0 }) {
            let convertedPoint = interactableSubview.convert(point, from: self)
            if let hitView = interactableSubview.hitTest(convertedPoint, with: event) {
                return hitView
            }
        }
        return textField
    }

    // MARK: - Private methods

    fileprivate func installConstraints() {
        if viewModel.editConfiguration == .readOnly {
            addAndPinSubview(transparentMaskView)
        }
        hStack = UIStackView(arrangedSubviews: [textFieldView, errorIconView, clearButton, accessoryContainerView])
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.setContentCompressionResistancePriority(textField.contentCompressionResistancePriority(for: .horizontal) + 1,
                                                            for: .horizontal)
        errorIconView.setContentHuggingPriority(.required, for: .horizontal)
        errorIconView.setContentCompressionResistancePriority(textField.contentCompressionResistancePriority(for: .horizontal) + 1,
                                                              for: .horizontal)
        accessoryContainerView.setContentHuggingPriority(.required, for: .horizontal)
        accessoryContainerView.setContentCompressionResistancePriority(textField.contentCompressionResistancePriority(for: .horizontal) + 1,
                                                                       for: .horizontal)
        hStack.alignment = .center
        hStack.spacing = 6
        addAndPinSubview(hStack, insets: ElementsUI.contentViewInsets)
    }

    @objc private func clearText() {
        textField.text = nil
        textField.sendActions(for: .editingChanged)
    }

    private func setClearButton(hidden: Bool) {
        UIView.performWithoutAnimation {
            clearButton.isHidden = hidden
            hStack.layoutIfNeeded()
        }
    }

    // MARK: - Internal methods

    func updateUI(with viewModel: TextFieldElement.ViewModel) {
        self.viewModel = viewModel

        // Update accessibility
        textField.accessibilityLabel = viewModel.accessibilityLabel

        // Update placeholder, text
        textFieldView.placeholder = viewModel.placeholder

        // Setting attributedText moves the cursor to the end, so we grab the cursor position now
        // Get the offset of the cursor from the end of the textField so it will keep
        // the same relative position in case attributedText adds more characters
        let cursorOffsetFromEnd = textField.selectedTextRange.map { textField.offset(from: textField.endOfDocument, to: $0.end) }

        // Don't mess with attributed text if the IME is currently in progress (Japanese/Chinese/Hindi characters)
        // Note: Setting textField.attributedText cancels the IME
        if textField.markedTextRange != nil {
            textField.text = viewModel.attributedText.string
        } else {
            textField.attributedText = viewModel.attributedText
        }

        if let cursorOffsetFromEnd = cursorOffsetFromEnd,
           let cursor = textField.position(from: textField.endOfDocument, offset: cursorOffsetFromEnd) {
            // Re-set the cursor back to where it was
            textField.selectedTextRange = textField.textRange(from: cursor, to: cursor)
        }
        textFieldView.updatePlaceholder(animated: false)

        // Update keyboard
        textField.autocapitalizationType = viewModel.keyboardProperties.autocapitalization
        textField.textContentType = viewModel.keyboardProperties.textContentType
        if viewModel.keyboardProperties.type != textField.keyboardType {
            textField.keyboardType = viewModel.keyboardProperties.type
#if !canImport(CompositorServices)
            textField.inputAccessoryView = textField.keyboardType.hasReturnKey ? nil : toolbar
#endif
            textField.reloadInputViews()
        }

        // Update text and border color
        if case .invalid(let error) = viewModel.validationState,
           error.shouldDisplay(isUserEditing: textField.isEditing) {
            layer.borderColor = viewModel.theme.colors.danger.cgColor
            textField.textColor = viewModel.theme.colors.danger
            errorIconView.alpha = 1
            textField.accessibilityValue = viewModel.attributedText.string + ", " + error.localizedDescription
        } else {
            layer.borderColor = viewModel.theme.colors.border.cgColor
            textField.textColor = viewModel.theme.colors.textFieldText.disabled(!isUserInteractionEnabled || !viewModel.editConfiguration.isEditable)
            errorIconView.alpha = 0
            textField.accessibilityValue = viewModel.attributedText.string
        }
        if frame != .zero {
            textField.layoutIfNeeded() // Fixes an issue on iOS 15 where setting textField properties cause it to lay out from zero size.
        }

        // Update accessory view
        accessoryView = viewModel.accessoryView

        accessibilityElements = [textFieldView, accessoryView].compactMap { $0 }
        // Manually call layoutIfNeeded to avoid unintentional animations
        // in next layout pass
        layoutIfNeeded()
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.transparentMaskView.backgroundColor = viewModel.theme.colors.componentBackground.translucentMaskColor
        updateUI(with: viewModel)
    }
#endif
}

// MARK: - UITextFieldDelegate

extension TextFieldView: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return viewModel.editConfiguration.isEditable
    }

    @objc func textDidChange() {
        // If the text updates to non-empty, ensure the clear button is visible
        if let text = textField.text, !text.isEmpty, viewModel.shouldShowClearButton {
            setClearButton(hidden: false)
        } else {
            // Did update to empty text
            setClearButton(hidden: true)
        }

        delegate?.textFieldViewDidUpdate(view: self)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // If text is already present in the text field we should show the clear button
        if let text = textField.text, !text.isEmpty, viewModel.shouldShowClearButton {
            setClearButton(hidden: false)
        }
        textFieldView.updatePlaceholder()
        delegate?.textFieldViewDidUpdate(view: self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        setClearButton(hidden: true) // Hide clear button when not editing
        textFieldView.updatePlaceholder()
        textField.layoutIfNeeded() // Without this, the text jumps for some reason
        delegate?.textFieldViewDidUpdate(view: self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.textFieldViewContinueToNextField(view: self)
        textField.resignFirstResponder()
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // This detects autofill specifically, which as of iOS 15 Apple only allows on empty text fields. This will also catch pastes into empty text fields.
        // This is not a perfect heuristic, but is sufficient for the purposes of being able to process autofilled text specifically (e.g. a phone number with unpredictable formatting that we want to parse)
        didReceiveAutofill = (text.isEmpty && range.length == 0 && range.location == 0 && string.count > 1)
        return true
    }
}

// MARK: - EventHandler

extension TextFieldView: EventHandler {
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

// MARK: - DoneButtonToolbarDelegate

extension TextFieldView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        textField.resignFirstResponder()
    }
}
