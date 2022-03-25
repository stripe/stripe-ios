//
//  FloatingPlaceholderView.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 10/19/21.
//

import UIKit

protocol FloatingPlaceholderContentView: UIView {
    var labelShouldFloat: Bool { get }
    var defaultResponder: UIView { get }
}

/**
 A helper view that contains a floating placeholder and a user-provided content view
 
 For internal SDK use only.
 */
@objc(STP_Internal_FloatingPlaceholderView)
class FloatingPlaceholderView: UIView {

    // MARK: - Views
    
    private let contentView: FloatingPlaceholderContentView

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = ElementsUITheme.current.colors.textFieldText
        return imageView
    }()
    
    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = ElementsUITheme.current.colors.placeholderText
        label.font = ElementsUITheme.current.fonts.subheadline
        return label
    }()
    
    public var shouldInsetContent: Bool = true {
        didSet {
            updateContentInsetConstraints()
        }
    }
    
    private func updateContentInsetConstraints() {
        let insets = ElementsUI.contentViewInsets

        contentInsetConstraints.top.constant = shouldInsetContent ? insets.top : 0
        contentInsetConstraints.bottom.constant = shouldInsetContent ? -insets.bottom : 0
        contentInsetConstraints.leading.constant = shouldInsetContent ? insets.leading : 0
        contentInsetConstraints.trailing.constant = shouldInsetContent ? -insets.trailing : 0
    }
    
    typealias ContentInsetConstraints = (top: NSLayoutConstraint, bottom: NSLayoutConstraint, leading: NSLayoutConstraint, trailing: NSLayoutConstraint)
    private lazy var contentInsetConstraints: ContentInsetConstraints = {
        return (
            top: hStack.topAnchor.constraint(equalTo: topAnchor),
            bottom: hStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            leading: hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailing: hStack.trailingAnchor.constraint(equalTo: trailingAnchor)
        )
    }()
    
    public var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
            // Update contentView top inset
            contentViewTopConstraint?.constant = topInset(for: placeholder)
            updatePlaceholder(animated: false)
        }
    }
    
    private var contentViewTopConstraint: NSLayoutConstraint? = nil
    
    private func topInset(for placeholder: String?) -> CGFloat {
        return placeholder != nil ?
            Constants.Placeholder.bottomPadding + placeholderLabel.font.lineHeight * Constants.Placeholder.scale :
            0
    }


    private lazy var hStack: UIStackView = {
        let contentViewContainer = UIView()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentViewContainer.addSubview(contentView)
        
        // Allow space for the minimized placeholder to sit above the content view
        let topConstraint = contentView.topAnchor.constraint(equalTo: contentViewContainer.topAnchor, constant:  topInset(for: placeholder))
        contentViewTopConstraint = topConstraint
        NSLayoutConstraint.activate([
            topConstraint,
            contentView.bottomAnchor.constraint(equalTo: contentViewContainer.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentViewContainer.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentViewContainer.trailingAnchor),
        ])
        
        let hStack = UIStackView(arrangedSubviews: [contentViewContainer, imageView])
        hStack.alignment = .center
        return hStack
    }()
    
    // MARK: - Initializers
    
    public init(contentView: FloatingPlaceholderContentView, image: UIImage? = nil) {
        self.contentView = contentView
        super.init(frame: .zero)
        imageView.image = image?.withRenderingMode(.alwaysTemplate)
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
            contentView.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }
    
    override var accessibilityValue: String? {
        set { assertionFailure() }
        get { return contentView.accessibilityValue }
    }
    
    override var accessibilityLabel: String? {
        set { assertionFailure() }
        get { return placeholderLabel.text }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        set { assertionFailure() }
        get { return contentView.accessibilityTraits }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, self.point(inside: point, with: event) else {
            return nil
        }
        // Forward all events within our bounds to the contentView
        return contentView.hitTest(contentView.convert(point, from: self), with: event) ?? contentView.defaultResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        guard !isHidden else {
            return false
        }
        return contentView.becomeFirstResponder()
    }
    
    // MARK: - Private methods
    
    fileprivate func installConstraints() {
        hStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hStack)
        updateContentInsetConstraints()

        imageView.setContentHuggingPriority(.required, for: .horizontal)
        // Arrange placeholder
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        // Change anchorpoint so scale transforms occur from the left instead of the center
        placeholderLabel.layer.anchorPoint = CGPoint(x: 0, y: 0.5)
        NSLayoutConstraint.activate([
            // Note placeholder's anchorPoint.x = 0 redefines its 'center' to the left
            placeholderLabel.centerXAnchor.constraint(equalTo: contentView.leadingAnchor),
            placeholderCenterYConstraint,
            contentInsetConstraints.top,
            contentInsetConstraints.bottom,
            contentInsetConstraints.leading,
            contentInsetConstraints.trailing,
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
        placeholderLabel.topAnchor.constraint(equalTo: hStack.topAnchor)
    }()
    
    public func updatePlaceholder(animated: Bool = true) {
        enum Position { case up, down }
        let position: Position = contentView.labelShouldFloat ? .up : .down
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

extension FloatingPlaceholderView: EventHandler {
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
        static let scale: CGFloat = 0.75
        /// The distance between the floating placeholder label and the content view below it.
        static let bottomPadding: CGFloat = 3.0
    }
}
