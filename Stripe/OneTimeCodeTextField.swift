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
    struct Constants {
        static let itemSpacing: CGFloat = 6
        static let groupSpacing: CGFloat = 20
    }

    /// Total number of digits of the one-time code.
    let numberOfDigits: Int

    /// The one-time code value without formatting.
    var value: String {
        get {
            return textStorage.value
        }
        set {
            textStorage.value = newValue
            update()
        }
    }

    var selectedTextRange: UITextRange? {
        willSet {
            inputDelegate?.selectionWillChange(self)
        }
        didSet {
            inputDelegate?.selectionDidChange(self)
            update()
        }
    }

    /// A Boolean value indicating whether the user has entered all the digits of the one-time code.
    var isComplete: Bool {
        return textStorage.isFull
    }

    var keyboardType: UIKeyboardType = .asciiCapableNumberPad

    var textContentType: UITextContentType? = {
        if #available(iOS 12.0, *) {
            return .oneTimeCode
        } else {
            return nil
        }
    }()

    var inputDelegate: UITextInputDelegate?

    lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)

    private let textStorage: TextStorage

    private var shouldGroupDigits: Bool {
        return numberOfDigits > 4 && numberOfDigits.isMultiple(of: 2)
    }

    private lazy var digitViews: [DigitView] = (0..<numberOfDigits).map { _ in
        return DigitView()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private let feedbackGenerator = UINotificationFeedbackGenerator()

    init(numberOfDigits: Int = 6) {
        self.numberOfDigits = numberOfDigits
        self.textStorage = TextStorage(capacity: numberOfDigits)
        super.init(frame: .zero)

        selectedTextRange = textStorage.endCaretRange

        isAccessibilityElement = true
        accessibilityLabel = STPLocalizedString(
            "Code field",
            "Accessibility label describing a field for entering a login code"
        )

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
            selectedTextRange = textStorage.endCaretRange
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
        let stackView = UIStackView(arrangedSubviews: arrangedDigitViews())
        stackView.spacing = shouldGroupDigits ? Constants.groupSpacing : Constants.itemSpacing
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        addAndPinSubview(stackView)
    }

    func arrangedDigitViews() -> [UIView] {
        guard shouldGroupDigits else {
            // No grouping, simply return all the digit views.
            return digitViews
        }

        // Split the digit views into two groups.
        let groupSize = numberOfDigits / 2

        let groups = stride(from: 0, to: digitViews.count, by: groupSize).map {
            Array(digitViews[$0..<min($0 + groupSize, digitViews.count)])
        }

        return groups.map {
            let groupView = UIStackView(arrangedSubviews: $0)
            groupView.spacing = Constants.itemSpacing
            groupView.distribution = .fillEqually
            return groupView
        }
    }

    func update() {
        updateDigitViews()
        updateAccessibilityProperties()
    }

    func updateDigitViews() {
        let digits: [Character] = .init(value)

        let selectedRange = selectedTextRange as? TextRange

        for (index, digitView) in digitViews.enumerated() {
            digitView.character = index < digits.count ? digits[index] : nil
            digitView.isActive = isFirstResponder && (selectedRange?.contains(index) ?? false)
        }
    }

    func updateAccessibilityProperties() {
        accessibilityValue = value

        accessibilityHint = isFirstResponder
            ? nil
            : STPLocalizedString("Double tap to edit", "Accessibility hint for a text field")
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

// MARK: - UIKeyInput

extension OneTimeCodeTextField: UIKeyInput {

    var hasText: Bool {
        return value.count > 0
    }

    func insertText(_ text: String) {
        guard let range = selectedTextRange as? TextRange else {
            return
        }

        inputDelegate?.textWillChange(self)
        selectedTextRange = textStorage.insert(text, at: range)
        inputDelegate?.textDidChange(self)

        sendActions(for: [.editingChanged, .valueChanged])
        hideMenu()
        update()
    }

    func deleteBackward() {
        guard let range = selectedTextRange as? TextRange else {
            return
        }

        inputDelegate?.textWillChange(self)
        selectedTextRange = textStorage.delete(range: range)
        inputDelegate?.textDidChange(self)

        sendActions(for: [.editingChanged, .valueChanged])
        hideMenu()
        update()
    }

}

// MARK: - UITextInput

extension OneTimeCodeTextField: UITextInput {

    var markedTextRange: UITextRange? {
        // We don't support marked text
        return nil
    }

    var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            return nil
        }
        set(markedTextStyle) {
            // We don't support marked text
        }
    }

    var beginningOfDocument: UITextPosition {
        return textStorage.start
    }

    var endOfDocument: UITextPosition {
        return textStorage.end
    }

    func text(in range: UITextRange) -> String? {
        guard let range = range as? TextRange else {
            return nil
        }

        return textStorage.text(in: range)
    }

    func replace(_ range: UITextRange, withText text: String) {
        // No-op
    }

    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        // We don't support marked text
    }

    func unmarkText() {
        // We don't support marked text
    }

    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard
            let fromPosition = fromPosition as? TextPosition,
            let toPosition = toPosition as? TextPosition
        else {
            return nil
        }

        return textStorage.makeRange(from: fromPosition, to: toPosition)
    }

    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let position = position as? TextPosition else {
            return nil
        }

        let newIndex = position.index + offset

        guard textStorage.extent.contains(newIndex) else {
            // Out of bounds
            return nil
        }

        return TextPosition(newIndex)
    }

    func position(
        from position: UITextPosition,
        in direction: UITextLayoutDirection,
        offset: Int
    ) -> UITextPosition? {
        switch direction {
        case .right:
            return self.position(from: position, offset: offset)
        case .left:
            return self.position(from: position, offset: -offset)
        case .up:
            return offset > 0 ? beginningOfDocument : endOfDocument
        case .down:
            return offset > 0 ? endOfDocument : beginningOfDocument
        @unknown default:
            return nil
        }
    }

    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard
            let position = position as? TextPosition,
            let other = other as? TextPosition
        else {
            return .orderedSame
        }

        return position.compare(other)
    }

    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard
            let from = from as? TextPosition,
            let toPosition = toPosition as? TextPosition
        else {
            return 0
        }

        return toPosition.index - from.index
    }

    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        guard let range = range as? TextRange else {
            return nil
        }

        switch direction {
        case .left, .up:
            return range.start
        case .right, .down:
            return range.end
        @unknown default:
            return nil
        }
    }

    func characterRange(
        byExtending position: UITextPosition,
        in direction: UITextLayoutDirection
    ) -> UITextRange? {
        switch direction {
        case .right:
            return self.textRange(from: position, to: endOfDocument)
        case .left:
            return self.textRange(from: beginningOfDocument, to: position)
        case .up, .down:
            return nil
        @unknown default:
            return nil
        }
    }

    func baseWritingDirection(
        for position: UITextPosition,
        in direction: UITextStorageDirection
    ) -> NSWritingDirection {
        // Numeric input should be left-to-right always.
        return .leftToRight
    }

    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        // No-op
    }

    func firstRect(for range: UITextRange) -> CGRect {
        guard let range = range as? TextRange else {
            return .zero
        }

        let firstDigitView = digitViews[range._start.index]
        let secondDigitView = digitViews[range._end.index]

        let firstRect = firstDigitView.convert(firstDigitView.bounds, to: self)
        let secondRect = firstDigitView.convert(secondDigitView.bounds, to: self)

        return firstRect.union(secondRect)
    }

    func caretRect(for position: UITextPosition) -> CGRect {
        guard let position = position as? TextPosition else {
            return .zero
        }

        let digitView = digitViews[position.index]
        return digitView.convert(digitView.caretRect, to: self)
    }

    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // No text-selection
        return []
    }

    func closestPosition(to point: CGPoint) -> UITextPosition? {
        return closestPosition(to: point, within: textStorage.extent)
    }

    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        guard
            let range = range as? TextRange,
            let digitView = hitTest(point, with: nil) as? DigitView,
            let index = digitViews.firstIndex(of: digitView)
        else {
            return nil
        }

        return range.contains(index) ? TextPosition(index) : nil
    }

    func characterRange(at point: CGPoint) -> UITextRange? {
        guard
            let startPosition = closestPosition(to: point) as? TextPosition,
            let endPosition = position(from: startPosition, offset: 1)
        else {
            return nil
        }

        return self.textRange(from: startPosition, to: endPosition)
    }

}

// MARK: - Digit View

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
            return label
        }()

        var caretRect: CGRect {
            let caretSize = CGSize(width: 2, height: font.ascender - font.descender)

            return CGRect(
                x: (bounds.width - caretSize.width) / 2,
                y: (bounds.height - caretSize.height) / 2,
                width: caretSize.width,
                height: caretSize.height
            )
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
            caret.frame = caretRect
            caret.cornerRadius = caret.frame.width / 2

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
