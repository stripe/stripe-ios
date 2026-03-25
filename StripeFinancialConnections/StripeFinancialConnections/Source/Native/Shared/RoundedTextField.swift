//
//  RoundedTextField.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/30/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol RoundedTextFieldDelegate: AnyObject {
    func roundedTextField(
        _ textField: RoundedTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool
    func roundedTextField(
        _ textField: RoundedTextField,
        textDidChange text: String
    )
    func roundedTextFieldUserDidPressReturnKey(_ textField: RoundedTextField)
    func roundedTextFieldDidEndEditing(_ textField: RoundedTextField)
}

final class RoundedTextField: UIView {

    private let showDoneToolbar: Bool
    private let appearance: FinancialConnectionsAppearance

    // Used to optionally add an error message
    // at the bottom of the text field
    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                containerHorizontalStackView,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 6
        return verticalStackView
    }()
    lazy var containerHorizontalStackView: UIStackView = {
        let containerStackView = UIStackView(
            arrangedSubviews: [
                textFieldContainerView
            ]
        )
        containerStackView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        containerStackView.axis = .horizontal
        containerStackView.spacing = 12
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 8,
            leading: 16,
            bottom: 8,
            trailing: 16
        )
        containerStackView.layer.cornerRadius = 12
        containerStackView.layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
        containerStackView.layer.shadowRadius = 2 / UIScreen.main.nativeScale
        containerStackView.layer.shadowOpacity = 0.1
        containerStackView.layer.shadowOffset = CGSize(
            width: 0,
            height: 1 / UIScreen.main.nativeScale
        )
        return containerStackView
    }()
    lazy var textFieldContainerView: UIView = {
        let textFieldStackView = UIStackView(
            arrangedSubviews: [
                textField
            ]
        )
        return textFieldStackView
    }()
    private(set) lazy var textField: UITextField = {
        let textField = IncreasedHitTestTextField()
        textField.font = FinancialConnectionsFont.label(.large).uiFont
        textField.textColor = FinancialConnectionsAppearance.Colors.textDefault
        textField.defaultPlaceholderColor = FinancialConnectionsAppearance.Colors.textSubdued
        textField.floatingPlaceholderColor = FinancialConnectionsAppearance.Colors.textSubdued
        textField.placeholderLabel.font = textField.font
        textField.tintColor = textField.textColor
        textField.delegate = self
        if showDoneToolbar {
            textField.inputAccessoryView = keyboardToolbar
        }
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // not ideal, but height constraint fixes an odd bug
            // where on landscape the text field gets compressed
            textField.heightAnchor.constraint(
                greaterThanOrEqualToConstant: FloatingPlaceholderTextField.LayoutConstants.defaultHeight
            ),
        ])
        return textField
    }()
    private var currentFooterView: UIView?
    private lazy var keyboardToolbar: DoneButtonToolbar = {
        var theme: ElementsAppearance = .default
        theme.colors = {
            var colors = ElementsAppearance.Color()
            colors.primary = self.appearance.colors.primary
            colors.secondaryText = FinancialConnectionsAppearance.Colors.textSubdued
            return colors
        }()
        let keyboardToolbar = DoneButtonToolbar(
            delegate: self,
            showCancelButton: false,
            theme: theme
        )
        return keyboardToolbar
    }()

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
    weak var delegate: RoundedTextFieldDelegate?

    init(
        placeholder: String,
        footerText: String? = nil,
        showDoneToolbar: Bool = false,
        appearance: FinancialConnectionsAppearance
    ) {
        self.showDoneToolbar = showDoneToolbar
        self.appearance = appearance
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
        textField.placeholder = placeholder
        self.footerText = footerText
        didUpdateFooterText()  // simulate `didSet`. it not get called in `init`
        updateBorder(highlighted: false)
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    override func endEditing(_ force: Bool) -> Bool {
        return textField.endEditing(force)
    }

    private func didUpdateFooterText() {
        currentFooterView?.removeFromSuperview()
        currentFooterView = nil

        let footerTextLabel: UIView?
        if let errorText = errorText, footerText != nil {
            footerTextLabel = CreateErrorLabel(text: errorText)
        } else if let errorText = errorText {
            footerTextLabel = CreateErrorLabel(text: errorText)
        } else if let footerText = footerText {
            let footerLabel = AttributedLabel(
                font: .label(.large),
                textColor: FinancialConnectionsAppearance.Colors.textDefault
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
        if errorText != nil && !highlighted {
            containerHorizontalStackView.layer.borderColor = FinancialConnectionsAppearance.Colors.textCritical.cgColor
            containerHorizontalStackView.layer.borderWidth = 2.0
        } else {
            if highlighted {
                containerHorizontalStackView.layer.borderColor = appearance.colors.textFieldFocused.cgColor
                containerHorizontalStackView.layer.borderWidth = 2.0
            } else {
                containerHorizontalStackView.layer.borderColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
                containerHorizontalStackView.layer.borderWidth = 1.0
            }
        }
    }

    @IBAction private func textFieldDidChange() {
        delegate?.roundedTextField(self, textDidChange: text)
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        updateBorder(highlighted: textField.isFirstResponder)
        containerHorizontalStackView.layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
    }
}

// MARK: - UITextFieldDelegate

extension RoundedTextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorder(highlighted: true)
    }

    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        return delegate?.roundedTextField(
            self,
            shouldChangeCharactersIn: range,
            replacementString: string
        ) ?? true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        delegate?.roundedTextFieldUserDidPressReturnKey(self)

        // the return value (whether true or false) seems to be a no-op
        // in all practical test cases
        return false
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        updateBorder(highlighted: false)
        delegate?.roundedTextFieldDidEndEditing(self)
    }
}

// MARK: - DoneButtonToolbarDelegate

extension RoundedTextField: DoneButtonToolbarDelegate {
    func didTapDone(_ toolbar: DoneButtonToolbar) {
        textField.endEditing(true)
    }
}

private func CreateErrorLabel(text: String) -> UIView {
    let errorLabel = AttributedTextView(
        font: .label(.small),
        boldFont: .label(.smallEmphasized),
        linkFont: .label(.small),
        textColor: FinancialConnectionsAppearance.Colors.textCritical,
        linkColor: FinancialConnectionsAppearance.Colors.textCritical
    )
    errorLabel.setText(text)
    return errorLabel
}

private class IncreasedHitTestTextField: FloatingPlaceholderTextField {
    // increase the area of TextField taps
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let largerBounds = bounds.insetBy(dx: -16, dy: -16)
        return largerBounds.contains(point)
    }
}

private class FloatingPlaceholderTextField: UITextField {

    fileprivate struct LayoutConstants {
        static let defaultHeight: CGFloat = 40

        static let horizontalMargin: CGFloat = 0
        static let horizontalSpacing: CGFloat = 4

        static let floatingPlaceholderScale: CGFloat = 0.75
    }

    private(set) lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = defaultPlaceholderColor
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    private var lastAnimator: UIViewPropertyAnimator?
    private var changingFirstResponderStatus = false
    var defaultPlaceholderColor: UIColor = FinancialConnectionsAppearance.Colors.textSubdued
    var floatingPlaceholderColor: UIColor = FinancialConnectionsAppearance.Colors.textSubdued
    private var placeholderColor: UIColor {
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
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        // even though the default font value for UITextFields is body, on iOS 13 at least they do not respect
        // the font size settings. Resetting here fixes
        font = UIFont.preferredFont(forTextStyle: .body)
        adjustsFontForContentSizeCategory = true

        placeholderLabel.font = font
        placeholderLabel.textAlignment = textAlignment
        placeholderColor = defaultPlaceholderColor
        addSubview(placeholderLabel)
    }

    private func floatingPlaceholderHeight() -> CGFloat {
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
            * FloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale
    }

    private func contentPadding() -> UIEdgeInsets {

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
                FloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale
                    * (availableHeight - floatingPlaceholderLabelHeight
                        - (floatingPlaceholderLabelHeight
                            / FloatingPlaceholderTextField.LayoutConstants
                            .floatingPlaceholderScale))
                    / CGFloat(2)
            ) : 0

        var leftMargin = FloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        if leftView != nil,
            leftViewMode == .always
        {
            leftMargin =
                leftMargin + self.leftViewRect(forBounds: bounds).width
                + FloatingPlaceholderTextField.LayoutConstants.horizontalSpacing
        }

        var rightMargin = FloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        if rightView != nil,
            rightViewMode == .always
        {
            rightMargin =
                rightMargin + self.rightViewRect(forBounds: bounds).width
                + FloatingPlaceholderTextField.LayoutConstants.horizontalSpacing
        }

        let isRTL = traitCollection.layoutDirection == .rightToLeft

        return UIEdgeInsets(
            top: vMargin,
            left: isRTL ? rightMargin : leftMargin,
            bottom: vMargin,
            right: isRTL ? leftMargin : rightMargin
        )
    }

    private func textEntryFieldInset() -> UIEdgeInsets {
        var inset = contentPadding()
        if isEditing || !(text?.isEmpty ?? true) {
            // contentPadding pads the top to the floating placeholder so for text
            // entry we need to offset past that
            let floatingPlaceholderLabelHeight = floatingPlaceholderHeight()
            inset.top = inset.top + floatingPlaceholderLabelHeight
        }
        return inset
    }

    private func textEntryFrame() -> CGRect {
        return bounds.inset(by: textEntryFieldInset())
    }

    private func layoutPlaceholder(animated: Bool) {
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
            let scale = FloatingPlaceholderTextField.LayoutConstants.floatingPlaceholderScale

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

    // MARK: - UITextField Overrides

    override var placeholder: String? {
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

    override var attributedPlaceholder: NSAttributedString? {
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

    override var font: UIFont? {
        didSet {
            placeholderLabel.font = font
        }
    }

    override var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }

    override var leftViewMode: UITextField.ViewMode {
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

    override var rightViewMode: UITextField.ViewMode {
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

    override func layoutSubviews() {
        super.layoutSubviews()
        // internally, becoming first responder triggers a layout which we want to suppress
        // so we can animate
        if !changingFirstResponderStatus {
            layoutPlaceholder(animated: false)
        }
    }

    override func becomeFirstResponder() -> Bool {
        changingFirstResponderStatus = true
        let ret = super.becomeFirstResponder()
        layoutPlaceholder(animated: true)
        changingFirstResponderStatus = false
        return ret
    }

    override func resignFirstResponder() -> Bool {
        changingFirstResponderStatus = true
        let ret = super.resignFirstResponder()
        layoutPlaceholder(animated: true)
        changingFirstResponderStatus = false
        return ret
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        // N.B. The bounds passed here are not the same as self.bounds
        // which is why we don't just use textEntryFrame()
        return bounds.inset(by: textEntryFieldInset())
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        // N.B. The bounds passed here are not the same as self.bounds
        // which is why we don't just use textEntryFrame()
        return bounds.inset(by: textEntryFieldInset())
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        // N.B. The bounds passed here are not the same as self.bounds
        // which is why we don't just use textEntryFrame()
        return bounds.inset(by: textEntryFieldInset())
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var leftViewRect = super.leftViewRect(forBounds: bounds)
        leftViewRect.origin.x =
            leftViewRect.origin.x + FloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        return leftViewRect
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rightViewRect = super.rightViewRect(forBounds: bounds)
        rightViewRect.origin.x =
            rightViewRect.origin.x
            - FloatingPlaceholderTextField.LayoutConstants.horizontalMargin
        return rightViewRect
    }

    override var intrinsicContentSize: CGSize {
        let height = UIFontMetrics.default.scaledValue(
            for: FloatingPlaceholderTextField.LayoutConstants.defaultHeight
        )
        let contentPadding = self.contentPadding()
        return CGSize(
            width: placeholderLabel.intrinsicContentSize.width + contentPadding.left
                + contentPadding.right,
            height: height
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = max(size.height, intrinsicContentSize.height)
        size.width = max(size.width, intrinsicContentSize.width)
        return size
    }

    override func systemLayoutSizeFitting(
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

#if DEBUG

import SwiftUI

private struct RoundedTextFieldUIViewRepresentable: UIViewRepresentable {

    let placeholder: String
    let footerText: String?
    let errorText: String?
    let isFocused: Bool
    let appearance: FinancialConnectionsAppearance

    func makeUIView(context: Context) -> RoundedTextField {
        RoundedTextField(
            placeholder: placeholder,
            footerText: footerText,
            appearance: appearance
        )
    }

    func updateUIView(_ uiView: RoundedTextField, context: Context) {
        if isFocused {
            _ = uiView.becomeFirstResponder()
        }

        uiView.errorText = errorText
    }
}

struct RoundedTextField_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                RoundedTextFieldUIViewRepresentable(
                    placeholder: "Routing number",
                    footerText: nil,
                    errorText: nil,
                    isFocused: false,
                    appearance: .stripe
                )
                .frame(height: 56)
                RoundedTextFieldUIViewRepresentable(
                    placeholder: "Account number",
                    footerText: "Your account can be checkings or savings.",
                    errorText: nil,
                    isFocused: false,
                    appearance: .stripe
                )
                .frame(height: 80)
                RoundedTextFieldUIViewRepresentable(
                    placeholder: "Confirm account number",
                    footerText: nil,
                    errorText: nil,
                    isFocused: false,
                    appearance: .stripe
                )
                .frame(height: 56)
                RoundedTextFieldUIViewRepresentable(
                    placeholder: "Routing number",
                    footerText: nil,
                    errorText: "Routing number is required.",
                    isFocused: false,
                    appearance: .stripe
                )
                .frame(height: 80)
                RoundedTextFieldUIViewRepresentable(
                    placeholder: "Account number",
                    footerText: "Your account can be checkings or savings.",
                    errorText: "Account number is required.",
                    isFocused: false,
                    appearance: .stripe
                )
                .frame(height: 80)
                Spacer()
            }
            .padding()
            .background(Color(FinancialConnectionsAppearance.Colors.background))

            // Use separate devices to showcase highlighted state
            RoundedTextFieldUIViewRepresentable(
                placeholder: "Light theme",
                footerText: nil,
                errorText: nil,
                isFocused: true,
                appearance: .stripe
            )
            .frame(height: 56)
            .padding()
            .previewDisplayName("Focused - Light theme")

            RoundedTextFieldUIViewRepresentable(
                placeholder: "Link Light theme",
                footerText: nil,
                errorText: nil,
                isFocused: true,
                appearance: .link
            )
            .frame(height: 56)
            .padding()
            .previewDisplayName("Focused - Link Light theme")
        }
    }
}

#endif
