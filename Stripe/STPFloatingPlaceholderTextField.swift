//
//  STPFloatingPlaceholderTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/7/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

/// A `UITextField` subclass that moves the placeholder text to the top leading side of the field
/// instead of hiding it upon text entry or editing.
class STPFloatingPlaceholderTextField: UITextField {

    struct LayoutConstants {
        static let defaultHeight: CGFloat = 40

        static let horizontalMargin: CGFloat = 11
        static let horizontalSpacing: CGFloat = 4

        static let floatingPlaceholderScale: CGFloat = 0.75

        static let defaultPlaceholderColor: UIColor = CompatibleColor.secondaryLabel

        static let floatingPlaceholderColor: UIColor = CompatibleColor.secondaryLabel
    }

    let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = STPFloatingPlaceholderTextField.LayoutConstants.defaultPlaceholderColor
        return label
    }()

    var lastAnimator: UIViewPropertyAnimator?

    var changingFirstResponderStatus = false

    var defaultPlaceholderColor: UIColor = STPFloatingPlaceholderTextField.LayoutConstants
        .defaultPlaceholderColor
    var floatingPlaceholderColor: UIColor = STPFloatingPlaceholderTextField.LayoutConstants
        .floatingPlaceholderColor

    var placeholderColor: UIColor {
        get {
            return placeholderLabel.textColor
        }
        set {
            placeholderLabel.textColor = newValue
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }

    func setupSubviews() {
        // even though the default font value for UITextFields is body, on iOS 13 at least they do not respect
        // the font size settings. Resetting here fixes
        font = UIFont.preferredFont(forTextStyle: .body)

        placeholderLabel.font = font
        placeholderLabel.textAlignment = textAlignment
        placeholderColor = defaultPlaceholderColor
        addSubview(placeholderLabel)
    }

    func floatingPlaceholderHeight() -> CGFloat {
        let placeholderLabelHeight = placeholderLabel.textRect(
            forBounds: CGRect(
                x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude), limitedToNumberOfLines: 1
        ).height
        return placeholderLabelHeight
            * STPFloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale
    }

    func contentPadding() -> UIEdgeInsets {

        let floatingPlaceholderLabelHeight = floatingPlaceholderHeight()
        let availableHeight = bounds.height

        /*

         |----------------------------------------------------|
         |_______|vMargin_____________________________________|
         |       |                                            |
         |_______|floatingPlacholderLabelHeight_______________|
         |       |                                            |
         |       |                                            | availableHeight
         |       |                                            |
         |_______|textEntryHeight_____________________________|
         |_______|vMargin_____________________________________|

         vMargin is calculated as follows:

         We want the text content to be vertically centered, giving the equation:
            (floatingPlaceholderLabelHeight + textEntryHeight)/2 = availableHeight/2

         We want the distance from the top to the midpoint of the floating placeholder to
         be the same as the distance from the bottom to the center of the text entry rect,
         but scaled by floatingPlaceholderScale giving:
            floatingPlaceholderScale * (textEntryHeight/2 + vMargin) = floatingPlacholderLabelHeight/2 + vMargin

         */

        let vMargin =
            floatingPlaceholderLabelHeight > 0
            ? max(
                0,
                STPFloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale
                    * (availableHeight - floatingPlaceholderLabelHeight
                        - (floatingPlaceholderLabelHeight
                            / STPFloatingPlaceholderTextField.LayoutConstants
                            .floatingPlaceholderScale))
                    / CGFloat(2)) : 0

        var leftMargin = STPFloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        if leftView != nil,
            leftViewMode == .always
        {
            leftMargin =
                leftMargin + self.leftViewRect(forBounds: bounds).width
                + STPFloatingPlaceholderTextField.LayoutConstants.horizontalSpacing
        }

        var rightMargin = STPFloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        if rightView != nil,
            rightViewMode == .always
        {
            rightMargin =
                rightMargin + self.rightViewRect(forBounds: bounds).width
                + STPFloatingPlaceholderTextField.LayoutConstants.horizontalSpacing
        }

        let isRTL = traitCollection.layoutDirection == .rightToLeft

        return UIEdgeInsets(
            top: vMargin, left: isRTL ? rightMargin : leftMargin, bottom: vMargin,
            right: isRTL ? leftMargin : rightMargin)
    }

    func textEntryFieldInset() -> UIEdgeInsets {
        var inset = contentPadding()
        if isEditing || !(text?.isEmpty ?? true) {
            // contentPadding pads the top to the floating placeholder so for text
            // entry we need to offset past that
            let floatingPlaceholderLabelHeight = floatingPlaceholderHeight()
            inset.top = inset.top + floatingPlaceholderLabelHeight
        }
        return inset
    }

    func textEntryFrame() -> CGRect {
        return bounds.inset(by: textEntryFieldInset())
    }

    func layoutPlaceholder(animated: Bool) {
        guard !(placeholder?.isEmpty ?? true) else {
            return
        }
        layoutIfNeeded()

        var placeholderFrame = textEntryFrame()
        placeholderFrame.size.width = min(
            placeholderFrame.size.width,
            placeholderLabel.textRect(forBounds: placeholderFrame, limitedToNumberOfLines: 1).width)
        if traitCollection.layoutDirection == .rightToLeft {
            placeholderFrame.origin.x = textEntryFrame().maxX - placeholderFrame.width
        }
        var placeholderTransform = CGAffineTransform.identity
        var placeholderColor: UIColor = defaultPlaceholderColor

        let minimized = isEditing || !(text?.isEmpty ?? true)

        if minimized {
            let scale = STPFloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale

            placeholderFrame.origin.y = self.contentPadding().top
            if traitCollection.layoutDirection == .rightToLeft {
                // shift origin to the right by the amount the text is compressed horizontally
                placeholderFrame.origin.x =
                    placeholderFrame.origin.x + (1 - scale) * placeholderFrame.width
            }
            placeholderFrame.size.width = placeholderFrame.width * scale  // scaling the width here leads to a clean up and down animation
            placeholderFrame.size.height =
                placeholderLabel.textRect(forBounds: placeholderFrame, limitedToNumberOfLines: 1)
                .height * scale
            placeholderTransform = placeholderTransform.scaledBy(x: scale, y: scale)
            placeholderColor = floatingPlaceholderColor
        }

        if animated {
            // Stop any in-flight animations
            lastAnimator?.stopAnimation(true)
            let params = UISpringTimingParameters(
                mass: 1.0, dampingRatio: 0.93, frequencyResponse: 0.22)
            let animator = UIViewPropertyAnimator(duration: 0, timingParameters: params)
            animator.isInterruptible = true
            animator.addAnimations {
                self.placeholderLabel.transform = placeholderTransform
                self.placeholderLabel.frame = placeholderFrame
                if !minimized {
                    // when we are animating back to center, change color immediately
                    self.placeholderColor = placeholderColor
                }
            }
            animator.addCompletion { (_) in
                if minimized {
                    // when animating away from center, change color at end of animation
                    self.placeholderColor = placeholderColor
                }
            }
            animator.startAnimation()
            self.lastAnimator = animator
        } else {
            placeholderLabel.transform = placeholderTransform
            placeholderLabel.frame = placeholderFrame
            self.placeholderColor = placeholderColor
        }
    }

}

// MARK: UITextField Overrides
extension STPFloatingPlaceholderTextField {

    /// :nodoc:
    @objc public override var placeholder: String? {
        get {
            return placeholderLabel.text
        }
        set {
            placeholderLabel.text = newValue
            self.accessibilityLabel = newValue
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// :nodoc:
    @objc public override var attributedPlaceholder: NSAttributedString? {
        get {
            return placeholderLabel.attributedText
        }
        set {
            placeholderLabel.attributedText = newValue
            self.accessibilityLabel = newValue?.string
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// :nodoc:
    @objc public override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }

    /// :nodoc:
    @objc public override var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }

    /// :nodoc:
    @objc public override var leftViewMode: UITextField.ViewMode {
        set {
            if newValue != .always && newValue != .never {
                assert(false, "Only .always or .never are supported")
                super.leftViewMode = .never
            } else {
                super.leftViewMode = newValue
            }
        }
        get {
            return super.leftViewMode
        }
    }

    /// :nodoc:
    @objc public override var rightViewMode: UITextField.ViewMode {
        set {
            if newValue != .always && newValue != .never {
                assert(false, "Only .always or .never are supported")
                super.rightViewMode = .never
            } else {
                super.rightViewMode = newValue
            }
        }
        get {
            return super.rightViewMode
        }
    }

    /// :nodoc:
    @objc public override func layoutSubviews() {
        super.layoutSubviews()
        // internally, becoming first responder triggers a layout which we want to suppress
        // so we can animate
        if !changingFirstResponderStatus {
            layoutPlaceholder(animated: false)
        }
    }

    /// :nodoc:
    @objc public override func becomeFirstResponder() -> Bool {
        changingFirstResponderStatus = true
        let ret = super.becomeFirstResponder()
        layoutPlaceholder(animated: true)
        changingFirstResponderStatus = false
        return ret
    }

    /// :nodoc:
    @objc public override func resignFirstResponder() -> Bool {
        changingFirstResponderStatus = true
        let ret = super.resignFirstResponder()
        layoutPlaceholder(animated: true)
        changingFirstResponderStatus = false
        return ret
    }

    /// :nodoc:
    @objc public override func textRect(forBounds bounds: CGRect) -> CGRect {
        // N.B. The bounds passed here are not the same as self.bounds
        // which is why we don't just use textEntryFrame()
        return bounds.inset(by: textEntryFieldInset())
    }

    /// :nodoc:
    @objc public override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        // N.B. The bounds passed here are not the same as self.bounds
        // which is why we don't just use textEntryFrame()
        return bounds.inset(by: textEntryFieldInset())
    }

    /// :nodoc:
    @objc public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        // N.B. The bounds passed here are not the same as self.bounds
        // which is why we don't just use textEntryFrame()
        return bounds.inset(by: textEntryFieldInset())
    }

    /// :nodoc:
    @objc public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var leftViewRect = super.leftViewRect(forBounds: bounds)
        leftViewRect.origin.x =
            leftViewRect.origin.x + STPFloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        return leftViewRect
    }

    /// :nodoc:
    @objc public override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rightViewRect = super.rightViewRect(forBounds: bounds)
        rightViewRect.origin.x =
            rightViewRect.origin.x
            - STPFloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        return rightViewRect
    }

    /// :nodoc:
    @objc public override var intrinsicContentSize: CGSize {
        let height = UIFontMetrics.default.scaledValue(
            for: STPFloatingPlaceholderTextField.LayoutConstants.defaultHeight)
        let contentPadding = self.contentPadding()
        return CGSize(
            width: placeholderLabel.intrinsicContentSize.width + contentPadding.left
                + contentPadding.right, height: height)
    }

    /// :nodoc:
    @objc public override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = max(size.height, intrinsicContentSize.height)
        size.width = max(size.width, intrinsicContentSize.width)
        return size
    }

    /// :nodoc:
    @objc public override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        var size = super.systemLayoutSizeFitting(
            targetSize, withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority)
        size.width = max(size.width, intrinsicContentSize.width)
        return size
    }
}
