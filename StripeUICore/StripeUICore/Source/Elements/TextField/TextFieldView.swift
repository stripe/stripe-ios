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
    func didUpdate(view: TextFieldView)
    func didEndEditing(view: TextFieldView)
}

/**
 A text input field view with a floating placeholder and images.
 - Seealso: `TextFieldElement.ViewModel`
 
 For internal SDK use only
 */
@objc(STP_Internal_TextFieldView)
class TextFieldView: UIView {
    weak var delegate: TextFieldViewDelegate?
    private lazy var toolbar = DoneButtonToolbar(delegate: self)
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
    
    // MARK: - Views
    
    private(set) lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.font = ElementsUITheme.current.fonts.subheadline
        return textField
    }()
    private lazy var textFieldView: FloatingPlaceholderTextFieldView = {
        return FloatingPlaceholderTextFieldView(textField: textField)
    }()
    private var viewModel: TextFieldElement.ViewModel
    
    // MARK: - Initializers
    
    init(viewModel: TextFieldElement.ViewModel, delegate: TextFieldViewDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(frame: .zero)
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
        
        // Forward all events within our bounds to the textfield
        return textField
    }
    
    override func becomeFirstResponder() -> Bool {
        guard !isHidden else {
            return false
        }
        return textField.becomeFirstResponder()
    }
    
    // MARK: - Private methods
    
    fileprivate func installConstraints() {
       addAndPinSubview(textFieldView)
    }

    // MARK: - Internal methods
    
    func updateUI(with viewModel: TextFieldElement.ViewModel) {
        self.viewModel = viewModel
        // Update layout
        textFieldView.shouldInsetContent = viewModel.shouldInsetContent
        
        // Update placeholder, text
        textFieldView.placeholder = viewModel.floatingPlaceholder
        if let staticPlaceholder = viewModel.staticPlaceholder {
            textField.attributedPlaceholder = NSAttributedString(string: staticPlaceholder,
                                                                 attributes: [.foregroundColor: ElementsUITheme.current.colors.placeholderText,
                                                                                          .font: ElementsUITheme.current.fonts.subheadline])
        } else {
            textField.attributedPlaceholder = nil
        }

        // Setting attributedText moves the cursor to the end, so we grab the cursor position now
        // Get the offset of the cursor from the end of the textField so it will keep
        // the same relative position in case attributedText adds more characters
        let cursorOffsetFromEnd = textField.selectedTextRange.map { textField.offset(from: textField.endOfDocument, to: $0.end) }

        textField.attributedText = viewModel.attributedText
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
            textField.inputAccessoryView = textField.keyboardType.hasReturnKey ? nil : toolbar
            textField.reloadInputViews()
        }
        
        // Update text and border color
        if case .invalid(let error) = viewModel.validationState,
           error.shouldDisplay(isUserEditing: textField.isEditing) {
            superview?.bringSubviewToFront(self)
            layer.borderColor = ElementsUITheme.current.colors.danger.cgColor
            textField.textColor = ElementsUITheme.current.colors.danger
        } else {
            layer.borderColor = ElementsUITheme.current.colors.border.cgColor
            textField.textColor = isUserInteractionEnabled ? ElementsUITheme.current.colors.textFieldText : CompatibleColor.tertiaryLabel
        }
        if frame != .zero {
            textField.layoutIfNeeded() // Fixes an issue on iOS 15 where setting textField properties cause it to lay out from zero size.
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateUI(with: viewModel)
    }
}

// MARK: - UITextFieldDelegate

extension TextFieldView: UITextFieldDelegate {
    @objc func textDidChange() {
        delegate?.didUpdate(view: self)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldView.updatePlaceholder()
        delegate?.didUpdate(view: self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldView.updatePlaceholder()
        textField.layoutIfNeeded() // Without this, the text jumps for some reason
        delegate?.didUpdate(view: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.didEndEditing(view: self)
        textField.resignFirstResponder()
        return false
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
        }
    }
}

// MARK: - DoneButtonToolbarDelegate

extension TextFieldView: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        delegate?.didEndEditing(view: self)
        textField.resignFirstResponder()
    }
}
