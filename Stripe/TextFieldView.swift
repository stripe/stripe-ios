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
        }
    }
 
    // MARK: - Views
    
    private lazy var image: UIImageView = {
        let image = UIImageView()
        image.isHidden = true // TODO: Support images
        return image
    }()
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.adjustsFontForContentSizeCategory = true
        textField.font = .preferredFont(forTextStyle: .body)
        return textField
    }()
    private lazy var placeholder: UILabel = {
        let label = UILabel()
        label.textColor = CompatibleColor.secondaryLabel
        label.font = UIFont.preferredFont(forTextStyle: .body)
        return label
    }()
    let placeholderScale: CGFloat = 0.75
    
    // MARK: - Initializers
    
    init(viewModel: TextFieldElement.ViewModel, delegate: TextFieldViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        installConstraints()
        updateUI(with: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private methods
    
    fileprivate func installConstraints() {
        image.setContentHuggingPriority(.required, for: .horizontal)
        
        // Allow space for the 'floating' placeholder above the text field
        let placeholderSmallHeight = placeholder.font.lineHeight * placeholderScale
        let placeholderAndTextfieldPadding: CGFloat = 2.0
        let textFieldContainer = UIView()
        textFieldContainer.addAndPinSubview(
            textField,
            insets: .insets(top: placeholderSmallHeight + placeholderAndTextfieldPadding)
        )
        
        textField.setContentCompressionResistancePriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        
        let hStack = UIStackView(arrangedSubviews: [image, textFieldContainer])
        hStack.setCustomSpacing(6, after: image)
        addAndPinSubview(hStack)
        
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        hStack.addSubview(placeholder)
        
        // Change anchorpoint so scale transforms occur from the left instead of the center
        placeholder.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        NSLayoutConstraint.activate([
            // Note placeholder's anchorPoint.x = 0 redefines its 'center' to the left
            placeholder.centerXAnchor.constraint(equalTo: textField.leadingAnchor),
            placeholderCenterYConstraint
        ])
    }

    // MARK: - Internal methods
    
    func updateUI(with viewModel: TextFieldElement.ViewModel) {
        // Update placeholder, text
        placeholder.text = {
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
        
        if textField.attributedText?.string != viewModel.attributedText.string {
            // Updating the text unnecessarily causes it to jump
            textField.attributedText = viewModel.attributedText
        }
        textField.textColor = {
            switch (isUserInteractionEnabled, viewModel.validationState) {
            case (false, _):
                return CompatibleColor.tertiaryLabel
            case (true, _):
                return CompatibleColor.label
            }
        }()

        // Update keyboard
        textField.autocapitalizationType = viewModel.keyboardProperties.autocapitalization
        if viewModel.keyboardProperties.type != textField.keyboardType {
            textField.keyboardType = viewModel.keyboardProperties.type
            textField.reloadInputViews()
        }
    }
    
    // MARK: - Animate placeholder
    
    lazy var animator: UIViewPropertyAnimator = {
        let params = UISpringTimingParameters(
            mass: 1.0,
            dampingRatio: 0.93,
            frequencyResponse: 0.22
        )
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)
        animator.isInterruptible = true
        return animator
    }()
    
    lazy var placeholderCenterYConstraint: NSLayoutConstraint = {
        placeholder.centerYAnchor.constraint(equalTo: centerYAnchor)
    }()
    
    lazy var placeholderTopYConstraint: NSLayoutConstraint = {
        placeholder.topAnchor.constraint(equalTo: topAnchor)
    }()
    
    func setPlaceholderLocation() {
        enum Position { case up, down }
        let position: Position = isEditing || !text.isEmpty ? .up : .down
        let scale = position == .up  ? placeholderScale : 1.0
        
        placeholder.transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
        placeholderCenterYConstraint.isActive = position != .up
        placeholderTopYConstraint.isActive = position == .up
        layoutIfNeeded()
    }

    fileprivate func animatePlaceholder() {
        animator.stopAnimation(true)
        animator.addAnimations {
            self.setPlaceholderLocation()
        }
        animator.startAnimation()
    }
}

// MARK: - UITextFieldDelegate

extension TextFieldView: UITextFieldDelegate {
    @objc func textDidChange() {
        delegate?.didUpdate(view: self)
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        animatePlaceholder()
        delegate?.didUpdate(view: self)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        animatePlaceholder()
        textField.layoutIfNeeded() // Without this, the text jumps for some reason
        delegate?.didUpdate(view: self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
        }
    }
}
