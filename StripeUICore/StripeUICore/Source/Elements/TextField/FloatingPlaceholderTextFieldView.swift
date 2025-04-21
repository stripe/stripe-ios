//
//  FloatingPlaceholderTextFieldView.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/**
 A helper view that contains a floating placeholder and a user-provided text field
 
 For internal SDK use only
 */
@objc(STP_Internal_FloatingPlaceholderTextFieldView)
class FloatingPlaceholderTextFieldView: UIView {

    // MARK: - Views

    private let textField: UITextField
    private let theme: ElementsAppearance
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = theme.colors.placeholderText
        label.font = theme.fonts.subheadline
        return label
    }()

    public var placeholder: String {
        get {
            return placeholderLabel.text ?? ""
        }
        set {
            placeholderLabel.text = newValue
        }
    }

    // MARK: - Initializers

    public init(textField: UITextField, theme: ElementsAppearance = .default) {
        self.textField = textField
        self.theme = theme
        super.init(frame: .zero)
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
        get { return textField.accessibilityValue }
        set { assertionFailure() } // swiftlint:disable:this unused_setter_value
    }

    override var accessibilityLabel: String? {
        get { return textField.accessibilityLabel ?? placeholderLabel.text }
        set { assertionFailure() } // swiftlint:disable:this unused_setter_value
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get { return textField.accessibilityTraits }
        set { assertionFailure() } // swiftlint:disable:this unused_setter_value
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
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)

        // Allow space for the minimized placeholder to sit above the textfield
        let minimizedPlaceholderHeight = placeholderLabel.font.lineHeight * Constants.Placeholder.scale
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor, constant: minimizedPlaceholderHeight + Constants.Placeholder.bottomPadding),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Arrange placeholder
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        // Change anchorPoint so scale transforms occur from the leading edge instead of the center
        placeholderLabel.layer.anchorPoint = effectiveUserInterfaceLayoutDirection == .leftToRight
            ? CGPoint(x: 0, y: 0.5)
            : CGPoint(x: 1, y: 0.5)
        NSLayoutConstraint.activate([
            // Note placeholder's anchorPoint.x = 0 redefines its 'center' to the left
            placeholderLabel.centerXAnchor.constraint(equalTo: textField.leadingAnchor),
            placeholderCenterYConstraint,
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
        placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
    }()

    fileprivate lazy var placeholderTopYConstraint: NSLayoutConstraint = {
        placeholderLabel.topAnchor.constraint(equalTo: topAnchor)
    }()

    public func updatePlaceholder(animated: Bool = true) {
        enum Position { case up, down }
        let isEmpty = textField.attributedText?.string.isEmpty ?? true
        let position: Position = textField.isEditing || !isEmpty ? .up : .down
        let scale = position == .up ? Constants.Placeholder.scale : 1.0
        let transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        let updatePlaceholderLocation = {
            self.placeholderLabel.transform = transform
            self.placeholderCenterYConstraint.isActive = position != .up
            self.placeholderTopYConstraint.isActive = position == .up
        }

        // Don't update redundantly; this can cause animation issues
        guard transform != self.placeholderLabel.transform else {
            return
        }

        // Note: Only animate if the view is inside of the window hierarchy,
        // otherwise calling `layoutIfNeeded` inside the animation block causes
        // autolayout errors
        guard animated && window != nil else {
            updatePlaceholderLocation()
            return
        }

        animator.stopAnimation(true)
        animator.addAnimations {
            updatePlaceholderLocation()
            self.layoutIfNeeded()
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
        default:
            break
        }
    }
}

// MARK: - Constants

private enum Constants {
    enum Placeholder {
        static let scale: CGFloat = 0.75
        /// The distance between the floating placeholder label and the textfield below it.
        static let bottomPadding: CGFloat = 3.0
    }
}
