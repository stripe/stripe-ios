//
//  TextFieldView.swift
//  StripeiOS
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
 */
class TextFieldView: UIView {
    weak var delegate: TextFieldViewDelegate?
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
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.font = Constants.textFieldFont
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
        // Update placeholder, text
        textFieldView.placeholder.text = {
            if !viewModel.isOptional {
                return viewModel.placeholder
            } else {
                let localized = STPLocalizedString(
                    "%@ (optional)",
                    "The label of a text field that is optional. For example, 'Email (optional)' or 'Name (optional)"
                )
                return String(format: localized, viewModel.placeholder)
            }
        }()
        
        textField.attributedText = viewModel.attributedText
        textField.textColor = {
            if case .invalid(let error) = viewModel.validationState,
               error.shouldDisplay(isUserEditing: textField.isEditing) {
                return UIColor.systemRed
            } else {
                return isUserInteractionEnabled ? CompatibleColor.label : CompatibleColor.tertiaryLabel
            }
        }()
        // Update keyboard
        textField.autocapitalizationType = viewModel.keyboardProperties.autocapitalization
        if viewModel.keyboardProperties.type != textField.keyboardType {
            textField.keyboardType = viewModel.keyboardProperties.type
            textField.reloadInputViews()
        }
    }
    
    /// Computes the height of a `TextFieldView`, as a hack to help other views be the same height
    /// - Seealso: DropdownFieldView.swift
    static var height: CGFloat {
        let textFieldHeight = Constants.textFieldFont.lineHeight
        let placeholderSmallHeight = Constants.Placeholder.font.lineHeight * Constants.Placeholder.scale
        return textFieldHeight + placeholderSmallHeight + Constants.Placeholder.bottomPadding
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

// MARK: - Constants

fileprivate enum Constants {
    enum Placeholder {
        static var font: UIFont {
            UIFont.preferredFont(forTextStyle: .body)
        }
        static let scale: CGFloat = 0.75
        /// The distance between the floating placeholder label and the text field below it.
        static let bottomPadding: CGFloat = 2.0
    }
    
    static let textFieldFont: UIFont = .preferredFont(forTextStyle: .body)
}
