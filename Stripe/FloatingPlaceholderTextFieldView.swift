//
//  FloatingPlaceholderTextFieldView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 7/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/**
 A helper view that contains a floating placeholder and a user-provided text field
 */
class FloatingPlaceholderTextFieldView: UIView {
    
    // MARK: - Views
    
    let textField: UITextField
    
    lazy var imageView: UIImageView = {
        return UIImageView()
    }()
    
    lazy var placeholder: UILabel = {
        let label = UILabel()
        label.textColor = CompatibleColor.secondaryLabel
        label.font = Constants.Placeholder.font
        return label
    }()

    lazy var hStack: UIStackView = {
        let textFieldContainer = UIView()
        // Allow space for the minimized placeholder to sit above the text field
        let minimizedPlaceholderHeight = placeholder.font.lineHeight * Constants.Placeholder.scale
        textFieldContainer.addAndPinSubview(
            textField,
            insets: .insets(top: minimizedPlaceholderHeight + Constants.Placeholder.bottomPadding)
        )
        let hStack = UIStackView(arrangedSubviews: [textFieldContainer, imageView])
        hStack.alignment = .center
        return hStack
    }()
    
    // MARK: - Initializers
    
    init(textField: UITextField, image: UIImage? = nil) {
        self.textField = textField
        super.init(frame: .zero)
        imageView.image = image
        imageView.isHidden = image == nil
        isAccessibilityElement = true
        installConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            textField.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }
    
    override var accessibilityValue: String? {
        set { assertionFailure() }
        get { return textField.text }
    }
    
    override var accessibilityLabel: String? {
        set { assertionFailure() }
        get { return placeholder.text }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        set { assertionFailure() }
        get { return textField.accessibilityTraits }
    }

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
        addAndPinSubview(hStack, insets: PaymentSheetUI.textfieldInsets)
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        // Arrange placeholder
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholder)
        // Change anchorpoint so scale transforms occur from the left instead of the center
        placeholder.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        NSLayoutConstraint.activate([
            // Note placeholder's anchorPoint.x = 0 redefines its 'center' to the left
            placeholder.centerXAnchor.constraint(equalTo: textField.leadingAnchor),
            placeholderCenterYConstraint
        ])
    }

    // MARK: - Animate placeholder
    
    fileprivate lazy var animator: UIViewPropertyAnimator = {
        let params = UISpringTimingParameters(
            mass: 1.0,
            dampingRatio: 0.93,
            frequencyResponse: 0.22
        )
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)
        animator.isInterruptible = true
        return animator
    }()
    
    fileprivate lazy var placeholderCenterYConstraint: NSLayoutConstraint = {
        placeholder.centerYAnchor.constraint(equalTo: centerYAnchor)
    }()
    
    fileprivate lazy var placeholderTopYConstraint: NSLayoutConstraint = {
        placeholder.topAnchor.constraint(equalTo: hStack.topAnchor)
    }()
    
    func updatePlaceholder(animated: Bool = true) {
        func updatePlaceholderLocation() {
            enum Position { case up, down }
            let isEmpty = (textField.text ?? "").isEmpty
            let position: Position = textField.isEditing || !isEmpty ? .up : .down
            let scale = position == .up  ? Constants.Placeholder.scale : 1.0
            
            placeholder.transform = CGAffineTransform.identity
                .scaledBy(x: scale, y: scale)
            placeholderCenterYConstraint.isActive = position != .up
            placeholderTopYConstraint.isActive = position == .up
            layoutIfNeeded()
        }
        
        guard animated else {
            updatePlaceholderLocation()
            return
        }
        
        animator.stopAnimation(true)
        animator.addAnimations {
            updatePlaceholderLocation()
        }
        animator.startAnimation()
    }
}

// MARK: - EventHandler

extension FloatingPlaceholderTextFieldView: EventHandler {
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
        static let bottomPadding: CGFloat = 3.0
    }
}
