//
//  ManualEntryTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/23/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol ManualEntryTextFieldDelegate: AnyObject {
    func manualEntryTextField(
        _ textField: ManualEntryTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool
    func manualEntryTextFieldDidBeginEditing(_ textField: ManualEntryTextField)
    func manualEntryTextFieldDidEndEditing(_ textField: ManualEntryTextField)
}

final class ManualEntryTextField: UIView {

    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                textFieldContainerView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 6
        return verticalStackView
    }()
    private lazy var titleLabel: AttributedLabel = {
        let titleLabel = AttributedLabel(
            font: .label(.largeEmphasized),
            textColor: .textPrimary
        )
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return titleLabel
    }()
    private lazy var textFieldContainerView: UIView = {
        let textFieldStackView = UIStackView(
            arrangedSubviews: [
                textField
            ]
        )
        textFieldStackView.axis = .vertical
        textFieldStackView.spacing = 0
        textFieldStackView.isLayoutMarginsRelativeArrangement = true
        textFieldStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8
            ,
            trailing: 16
        )
        textFieldStackView.layer.cornerRadius = 12
        return textFieldStackView
    }()
    private(set) lazy var textField: UITextField = {
        let textField = IncreasedHitTestTextField()
        textField.font = FinancialConnectionsFont.label(.large).uiFont
        textField.textColor = .textPrimary
        textField.keyboardType = .numberPad
        textField.delegate = self
        return textField
    }()
    private var currentFooterView: UIView?

    var text: String {
        get {
            return textField.text ?? ""
        }
        set {
            textField.text = newValue
        }
    }
    private var footerText: String? {
        didSet {
            didUpdateFooterText()
        }
    }
    var errorText: String? {
        didSet {
            didUpdateFooterText()
        }
    }
    weak var delegate: ManualEntryTextFieldDelegate?

    // TODO(kgaidis): delete title
    // TODO(kgaidis):  delete footerText
    init(title: String, placeholder: String, footerText: String? = nil) {
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: FinancialConnectionsFont.label(.large).uiFont,
                .foregroundColor: UIColor.textSubdued,
            ]
        )
        self.footerText = footerText
        didUpdateFooterText()  // simulate `didSet`. it not get called in `init`
        updateBorder(highlighted: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didUpdateFooterText() {
        currentFooterView?.removeFromSuperview()
        currentFooterView = nil

        let footerTextLabel: UIView?
        if let errorText = errorText, footerText != nil {
            footerTextLabel = ManualEntryErrorView(text: errorText)
        } else if let errorText = errorText {
            footerTextLabel = ManualEntryErrorView(text: errorText)
        } else if let footerText = footerText {
            let footerLabel = AttributedLabel(
                font: .label(.large),
                textColor: .textPrimary
            )
            footerLabel.text = footerText
            footerTextLabel = footerLabel
        } else {  // no text
            footerTextLabel = nil
        }
        if let footerTextLabel = footerTextLabel {
            verticalStackView.addArrangedSubview(footerTextLabel)
            currentFooterView = footerTextLabel
        }

        updateBorder(highlighted: textField.isFirstResponder)
    }

    private func updateBorder(highlighted: Bool) {
        let highlighted = textField.isFirstResponder

        if errorText != nil && !highlighted {
            textFieldContainerView.layer.borderColor = UIColor.textFeedbackCritical.cgColor
            textFieldContainerView.layer.borderWidth = 2.0
        } else {
            if highlighted {
                textFieldContainerView.layer.borderColor = UIColor.textActionPrimaryFocused.cgColor
                textFieldContainerView.layer.borderWidth = 2.0
            } else {
                textFieldContainerView.layer.borderColor = UIColor.borderNeutral.cgColor
                textFieldContainerView.layer.borderWidth = 1.0
            }
        }
    }
}

// MARK: - UITextFieldDelegate

extension ManualEntryTextField: UITextFieldDelegate {

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return delegate?.manualEntryTextField(
            self,
            shouldChangeCharactersIn: range,
            replacementString: string
        ) ?? true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorder(highlighted: true)
        delegate?.manualEntryTextFieldDidBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBorder(highlighted: false)
        delegate?.manualEntryTextFieldDidEndEditing(self)
    }
}

private class IncreasedHitTestTextField: STPFloatingPlaceholderTextField {
    // increase the area of TextField taps
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerBounds = bounds.insetBy(dx: -16, dy: -16)
        return largerBounds.contains(point)
    }
}

#if DEBUG

import SwiftUI

private struct ManualEntryTextFieldUIViewRepresentable: UIViewRepresentable {

    let title: String
    let placeholder: String
    let footerText: String?
    let errorText: String?

    func makeUIView(context: Context) -> ManualEntryTextField {
        ManualEntryTextField(
            title: title,
            placeholder: placeholder,
            footerText: footerText
        )
    }

    func updateUIView(_ uiView: ManualEntryTextField, context: Context) {
        uiView.errorText = errorText
    }
}

struct ManualEntryTextField_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Routing number",
                    placeholder: "Routing number",
                    footerText: nil,
                    errorText: nil
                )
                .frame(height: 80)
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Account number",
                    placeholder: "000123456789",
                    footerText: "Your account can be checkings or savings.",
                    errorText: nil
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Confirm account number",
                    placeholder: "000123456789",
                    footerText: nil,
                    errorText: nil
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Routing number",
                    placeholder: "123456789",
                    footerText: nil,
                    errorText: "Routing number is required."
                )
                ManualEntryTextFieldUIViewRepresentable(
                    title: "Account number",
                    placeholder: "000123456789",
                    footerText: "Your account can be checkings or savings.",
                    errorText: "Account number is required."
                )
                Spacer()
            }
//            .frame(maxHeight: 600)
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif

private class STPFloatingPlaceholderTextField: UITextField {

    struct LayoutConstants {
        static let defaultHeight: CGFloat = 40

        static let horizontalMargin: CGFloat = 0
        static let horizontalSpacing: CGFloat = 4

        static let floatingPlaceholderScale: CGFloat = 0.75

//        static let defaultPlaceholderColor: UIColor = .orange
//
//        static let floatingPlaceholderColor: UIColor = .red
    }

    private(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = defaultPlaceholderColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    var lastAnimator: UIViewPropertyAnimator?

    var changingFirstResponderStatus = false

    var defaultPlaceholderColor: UIColor = .textSubdued
    var floatingPlaceholderColor: UIColor = .textSubdued

    var placeholderColor: UIColor {
        get {
            return placeholderLabel.textColor
        }
        set {
            placeholderLabel.textColor = newValue
        }
    }

    override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
        setupSubviews()
    }

    func setupSubviews() {
        // even though the default font value for UITextFields is body, on iOS 13 at least they do not respect
        // the font size settings. Resetting here fixes
        font = UIFont.preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true

        placeholderLabel.font = font
        placeholderLabel.textAlignment = textAlignment
        placeholderColor = defaultPlaceholderColor
        addSubview(placeholderLabel)
    }

    func floatingPlaceholderHeight() -> CGFloat {
        let placeholderLabelHeight = placeholderLabel.textRect(
            forBounds: CGRect(
                x: 0,
                y: 0,
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            ),
            limitedToNumberOfLines: 1
        ).height
        return placeholderLabelHeight
            * STPFloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale
    }

    func contentPadding() -> UIEdgeInsets {

        let floatingPlaceholderLabelHeight = floatingPlaceholderHeight()
        let availableHeight = bounds.height

        //
        // |----------------------------------------------------|
        // |_______|vMargin_____________________________________|
        // |       |                                            |
        // |_______|floatingPlacholderLabelHeight_______________|
        // |       |                                            |
        // |       |                                            | availableHeight
        // |       |                                            |
        // |_______|textEntryHeight_____________________________|
        // |_______|vMargin_____________________________________|
        //
        // vMargin is calculated as follows:
        //
        // We want the text content to be vertically centered, giving the equation:
        //    (floatingPlaceholderLabelHeight + textEntryHeight)/2 = availableHeight/2
        //
        // We want the distance from the top to the midpoint of the floating placeholder to
        // be the same as the distance from the bottom to the center of the text entry rect,
        // but scaled by floatingPlaceholderScale giving:
        //    floatingPlaceholderScale * (textEntryHeight/2 + vMargin) = floatingPlacholderLabelHeight/2 + vMargin
        //

        let vMargin =
            floatingPlaceholderLabelHeight > 0
            ? max(
                0,
                STPFloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale
                    * (availableHeight - floatingPlaceholderLabelHeight
                        - (floatingPlaceholderLabelHeight
                            / STPFloatingPlaceholderTextField.LayoutConstants
                            .floatingPlaceholderScale))
                    / CGFloat(2)
            ) : 0

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
            top: vMargin,
            left: isRTL ? rightMargin : leftMargin,
            bottom: vMargin,
            right: isRTL ? leftMargin : rightMargin
        )
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
            placeholderLabel.textRect(forBounds: placeholderFrame, limitedToNumberOfLines: 1).width
        )
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
            // scaling the width here leads to a clean up and down animation
            placeholderFrame.size.width = placeholderFrame.width * scale
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
                mass: 1.0,
                dampingRatio: 0.93,
                frequencyResponse: 0.22
            )
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
        get {
            return super.leftViewMode
        }
        set {
            if newValue != .always && newValue != .never {
                assert(false, "Only .always or .never are supported")
                super.leftViewMode = .never
            } else {
                super.leftViewMode = newValue
            }
        }
    }

    /// :nodoc:
    @objc public override var rightViewMode: UITextField.ViewMode {
        get {
            return super.rightViewMode
        }
        set {
            if newValue != .always && newValue != .never {
                assert(false, "Only .always or .never are supported")
                super.rightViewMode = .never
            } else {
                super.rightViewMode = newValue
            }
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
            for: STPFloatingPlaceholderTextField.LayoutConstants.defaultHeight
        )
        let contentPadding = self.contentPadding()
        return CGSize(
            width: placeholderLabel.intrinsicContentSize.width + contentPadding.left
                + contentPadding.right,
            height: height
        )
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
            targetSize,
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
        size.width = max(size.width, intrinsicContentSize.width)
        return size
    }
}
