//
//  OneTimeCodeTextField.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

/// A field for collecting one-time codes (OTCs).
/// For internal SDK use only
@objc(STP_Internal_OneTimeCodeTextField)
final class OneTimeCodeTextField: UIControl {

    private static let itemSpacing: CGFloat = 6

    /// Total number of digits of the one-time code.
    let numberOfDigits: Int

    /// The one-time code value without formatting.
    var value: String = "" {
        didSet {
            update()
        }
    }

    /// A Boolean value indicating whether the user has entered all the digits of the one-time code.
    var isComplete: Bool {
        return value.count == numberOfDigits
    }

    var keyboardType: UIKeyboardType = .asciiCapableNumberPad

    var textContentType: UITextContentType? = {
        return .oneTimeCode
    }()

    private let allowedCharacters: CharacterSet = .init(charactersIn: "0123456789")

    private lazy var digitViews: [DigitView] = (0..<numberOfDigits).map { _ in
        return DigitView()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private let feedbackGenerator = UINotificationFeedbackGenerator()

    init(numberOfDigits: Int = 6) {
        self.numberOfDigits = numberOfDigits
        super.init(frame: .zero)

        isAccessibilityElement = true
        // TODO(ramont): Localize
        accessibilityLabel = "Code field"

        setupUI()

        // Trigger manual update to set its initial state.
        update()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()

        if result {
            update()
        }

        return result
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            hideMenu()
            update()
        }

        return result
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard let point = touches.first?.location(in: self),
              bounds.contains(point) else {
            return
        }

        if isFirstResponder {
            toggleMenu()
        } else {
            becomeFirstResponder()
        }
    }

}

// MARK: - Private methods

private extension OneTimeCodeTextField {

    func setupUI() {
        let stackView = UIStackView(arrangedSubviews: digitViews)
        stackView.spacing = Self.itemSpacing
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        addAndPinSubview(stackView)
    }

    func update() {
        updateDigitViews()
        updateAccessibilityProperties()
    }

    func updateDigitViews() {
        let digits: [Character] = .init(value)

        for (index, digitView) in digitViews.enumerated() {
            digitView.character = index < digits.count ? digits[index] : nil
            digitView.isActive = isFirstResponder && index == min(value.count, numberOfDigits - 1)
        }
    }

    func updateAccessibilityProperties() {
        accessibilityValue = value

        // TODO(ramont): Localize
        accessibilityHint = isFirstResponder ? nil : "Double tap to edit"
    }

    func toggleMenu() {
        if UIMenuController.shared.isMenuVisible {
            hideMenu()
        } else {
            showMenu()
        }
    }

    func showMenu() {
        let menuRect: CGRect = {
            guard let activeDigitView = digitViews.first(where: { $0.isActive }) else {
                return bounds
            }

            return activeDigitView.convert(activeDigitView.bounds, to: self)
        }()

        if #available(iOS 13.0, *) {
            UIMenuController.shared.showMenu(from: self, rect: menuRect)
        } else {
            UIMenuController.shared.setTargetRect(menuRect, in: self)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }

    func hideMenu() {
        if #available(iOS 13.0, *) {
            UIMenuController.shared.hideMenu()
        } else {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
    }

    @objc func applicationWillEnterForeground(_ notification: Notification) {
        // Forcing an update when the application enters foreground ensures that
        // the caret resumes blinking. This is something that iOS currently does for
        // long-running animation such as caret blinking on UITextField and
        // UIActivityIndicatorView spinning animation.
        update()
    }
}

// MARK: - UIKeyInput

extension OneTimeCodeTextField: UIKeyInput {

    var hasText: Bool {
        return value.count > 0
    }

    func insertText(_ text: String) {
        var tempValue = value

        for char in text {
            let validCharacter = char.unicodeScalars.allSatisfy(allowedCharacters.contains(_:))

            if validCharacter && tempValue.count < numberOfDigits {
                tempValue.append(char)
            }
        }

        value = tempValue
        sendActions(for: [.editingChanged, .valueChanged])
        hideMenu()
    }

    func deleteBackward() {
        _ = value.popLast()
        sendActions(for: [.editingChanged, .valueChanged])
        hideMenu()
    }

}

// MARK: - UIResponder

extension OneTimeCodeTextField {

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(paste(_:)) && UIPasteboard.general.hasStrings
    }

    override func paste(_ sender: Any?) {
        if let string = UIPasteboard.general.string {
            insertText(string)
            update()
        }
    }

}

// MARK: - Animation

extension OneTimeCodeTextField {

    /// Performs a shake animation, useful for indicating a bad code.
    /// - Parameter shouldClearValue: Whether or not the field's value should be cleared at the end of the animation.
    func performInvalidCodeAnimation(shouldClearValue: Bool = true) {
        // Temporarily disables user interaction while the animation plays.
        isUserInteractionEnabled = false

        let duration: CFTimeInterval = 0.4
        let beginTime = CACurrentMediaTime()
        let staggerDelay: CFTimeInterval = 0.025
        let timingFunction = CAMediaTimingFunction(controlPoints: 0.3, 0.3, 0.3, 1)

        for (index, digitView) in digitViews.enumerated() {
            // TODO(ramont): Move this to DigitView
            let jumpAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
            jumpAnimation.beginTime = beginTime + (CFTimeInterval(index) * staggerDelay)
            jumpAnimation.duration = duration
            jumpAnimation.values = [0, -8, 2, 0]
            jumpAnimation.keyTimes = [0.0, 0.33, 0.66, 1.0]
            jumpAnimation.timingFunctions = [timingFunction, timingFunction, timingFunction, timingFunction]

            let borderColorAnimation = CABasicAnimation(keyPath: "borderColor")
            borderColorAnimation.beginTime = beginTime + (CFTimeInterval(index) * staggerDelay)
            borderColorAnimation.duration = duration / 3
            borderColorAnimation.fromValue = UIColor.linkSeparator.cgColor
            borderColorAnimation.toValue = UIColor.systemRed.cgColor
            borderColorAnimation.fillMode = .forwards
            borderColorAnimation.isRemovedOnCompletion = false

            digitView.layer.add(jumpAnimation, forKey: "jump")
            digitView.borderLayer.add(borderColorAnimation, forKey: "borderColor")
        }

        feedbackGenerator.notificationOccurred(.error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.digitViews.forEach { digitView in
                digitView.layer.removeAllAnimations()
                digitView.borderLayer.removeAllAnimations()
            }

            if shouldClearValue {
                self?.value = ""
            }

            self?.isUserInteractionEnabled = true
            self?.becomeFirstResponder()
        }
    }

}

// MARK: - Digit view

private extension OneTimeCodeTextField {

    final class DigitView: UIView {
        struct Constants {
            static let dotSize: CGFloat = 8
            static let borderWidth: CGFloat = 1
            static let cornerRadius: CGFloat = 8
            static let focusRingThickness: CGFloat = 2
        }

        var isActive: Bool = false {
            didSet {
                updateLayers()
            }
        }

        var character: Character? {
            didSet {
                label.text = character.map { String($0) }
                updateLayers()
            }
        }

        private let font: UIFont = .systemFont(ofSize: 20)

        private(set) lazy var borderLayer: CALayer = {
            let borderLayer = CALayer()
            borderLayer.borderWidth = Constants.borderWidth
            borderLayer.cornerRadius = Constants.cornerRadius
            return borderLayer
        }()

        private lazy var focusRing: CALayer = {
            let focusRing = CALayer()
            focusRing.borderWidth = Constants.focusRingThickness
            focusRing.cornerRadius = Constants.cornerRadius + (Constants.focusRingThickness / 2)
            return focusRing
        }()

        private lazy var dot: CALayer = {
            let dot = CALayer()
            dot.frame = CGRect(x: 0, y: 0, width: Constants.dotSize, height: Constants.dotSize)
            dot.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            dot.cornerRadius = Constants.dotSize / 2
            return dot
        }()

        private lazy var caret: CALayer = .init()

        private lazy var label: UILabel = {
            let label = UILabel()
            label.textAlignment = .center
            label.isAccessibilityElement = false
            label.textColor = CompatibleColor.label
            label.font = font
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private var caretSize: CGSize {
            return CGSize(width: 2, height: font.ascender - font.descender)
        }

        override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: 60)
        }

        init() {
            super.init(frame: .zero)

            layer.addSublayer(borderLayer)
            layer.addSublayer(dot)
            layer.addSublayer(caret)
            layer.addSublayer(focusRing)

            addSubview(label)

            updateColors()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            label.frame = bounds
            borderLayer.frame = bounds

            // Center dot
            dot.position = CGPoint(x: bounds.midX, y: bounds.midY)

            // Update caret
            caret.cornerRadius = caretSize.width / 2
            caret.frame = CGRect(
                x: (bounds.width - caretSize.width) / 2,
                y: (bounds.height - caretSize.height) / 2,
                width: caretSize.width,
                height: caretSize.height
            )

            focusRing.frame = bounds.insetBy(
                dx: Constants.focusRingThickness / 2 * -1,
                dy: Constants.focusRingThickness / 2 * -1
            )
        }

        private func updateLayers() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)

            focusRing.isHidden = !isActive

            let isEmpty = character == nil
            let shouldShowDot = !isActive && isEmpty
            let shouldShowCaret = isActive && isEmpty

            dot.isHidden = !shouldShowDot

            if shouldShowCaret {
                showCaret()
            } else {
                hideCaret()
            }

            CATransaction.commit()
        }

        private func updateColors() {
            borderLayer.backgroundColor = UIColor.linkControlBackground.cgColor
            borderLayer.borderColor = UIColor.linkControlBorder.cgColor
            dot.backgroundColor = UIColor.linkControlLightPlaceholder.cgColor
            caret.backgroundColor = tintColor.cgColor
            focusRing.borderColor = tintColor.cgColor
        }

        private func showCaret() {
            caret.isHidden = false

            let blinkingAnimation = CAKeyframeAnimation(keyPath: "opacity")
            // Matches caret animation of iOS >= 13
            blinkingAnimation.keyTimes = [0, 0.5, 0.5375, 0.575, 0.6125, 0.65, 0.85, 0.8875, 0.925, 0.9625, 1]
            blinkingAnimation.values = [1, 1, 0.75, 0.5, 0.25, 0, 0, 0.25, 0.5, 0.75, 1]
            blinkingAnimation.duration = 1
            blinkingAnimation.repeatCount = .infinity
            blinkingAnimation.calculationMode = .discrete

            caret.add(blinkingAnimation, forKey: "blink")
        }

        private func hideCaret() {
            caret.isHidden = true
            caret.removeAllAnimations()
        }

        override func tintColorDidChange() {
            super.tintColorDidChange()
            updateColors()
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            updateColors()
        }
    }

}
