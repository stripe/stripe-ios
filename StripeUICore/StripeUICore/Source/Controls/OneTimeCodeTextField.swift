//
//  OneTimeCodeTextField.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/4/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// A field for collecting one-time codes (OTCs).
/// For internal SDK use only
@objc(STP_Internal_OneTimeCodeTextField)
@_spi(STP) public final class OneTimeCodeTextField: UIControl {
    private struct Constants {
        static let itemSpacing: CGFloat = 6
        static let groupSpacing: CGFloat = 20
    }

    /// Total number of digits of the one-time code.
    public let numberOfDigits: Int

    /// The one-time code value without formatting.
    public var value: String {
        get {
            return textStorage.value
        }
        set {
            textStorage.value = newValue
            update()
        }
    }

    /// A Boolean value indicating whether the user has entered all the digits of the one-time code.
    public var isComplete: Bool {
        return textStorage.isFull
    }

    public override var canBecomeFirstResponder: Bool {
        return true
    }

    // MARK: - Private properties

    private let theme: ElementsUITheme

    private let textStorage: TextStorage

    private var shouldGroupDigits: Bool {
        return numberOfDigits > 4 && numberOfDigits.isMultiple(of: 2)
    }

    private lazy var digitViews: [DigitView] = (0..<numberOfDigits).map { _ in
        return DigitView(theme: theme)
    }

    private let feedbackGenerator = UINotificationFeedbackGenerator()

    // MARK: - UIKeyInput properties

    public var keyboardType: UIKeyboardType = .asciiCapableNumberPad

    public var textContentType: UITextContentType? = .oneTimeCode

    // MARK: - UITextInput properties

    public var selectedTextRange: UITextRange? {
        willSet {
            inputDelegate?.selectionWillChange(self)
        }
        didSet {
            inputDelegate?.selectionDidChange(self)
            update()
        }
    }

    public var inputDelegate: UITextInputDelegate?

    public lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)

    // MARK: -
    public init(numberOfDigits: Int = 6, theme: ElementsUITheme = .default) {
        self.numberOfDigits = numberOfDigits
        self.textStorage = TextStorage(capacity: numberOfDigits)
        self.theme = theme
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
    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()

        if result {
            selectedTextRange = textStorage.endCaretRange
        }

        return result
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()

        if result {
            hideMenu()
            update()
        }

        return result
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
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
        stackView.semanticContentAttribute = .forceLeftToRight
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
            groupView.semanticContentAttribute = .forceLeftToRight
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

        UIMenuController.shared.showMenu(from: self, rect: menuRect)
    }

    func hideMenu() {
        UIMenuController.shared.hideMenu()
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

public extension OneTimeCodeTextField {

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

public extension OneTimeCodeTextField {

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
            borderColorAnimation.fromValue = theme.colors.border.cgColor
            borderColorAnimation.toValue = theme.colors.danger.cgColor
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

    public var hasText: Bool {
        return value.count > 0
    }

    public func insertText(_ text: String) {
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

    public func deleteBackward() {
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

// MARK: - Utils

extension OneTimeCodeTextField {

    private func clampIndex(_ index: Int) -> Int {
        return max(min(index, numberOfDigits - 1), 0)
    }

}

// MARK: - UITextInput

extension OneTimeCodeTextField: UITextInput {

    public var markedTextRange: UITextRange? {
        // We don't support marked text
        return nil
    }

    public var markedTextStyle: [NSAttributedString.Key: Any]? {
        get {
            return nil
        }
        set(markedTextStyle) {
            // We don't support marked text
        }
    }

    public var beginningOfDocument: UITextPosition {
        return textStorage.start
    }

    public var endOfDocument: UITextPosition {
        return textStorage.end
    }

    public func text(in range: UITextRange) -> String? {
        guard let range = range as? TextRange else {
            return nil
        }

        return textStorage.text(in: range)
    }

    public func replace(_ range: UITextRange, withText text: String) {
        // No-op
    }

    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        // We don't support marked text
    }

    public func unmarkText() {
        // We don't support marked text
    }

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard
            let fromPosition = fromPosition as? TextPosition,
            let toPosition = toPosition as? TextPosition
        else {
            return nil
        }

        return textStorage.makeRange(from: fromPosition, to: toPosition)
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
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

    public func position(
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

    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard
            let position = position as? TextPosition,
            let other = other as? TextPosition
        else {
            return .orderedSame
        }

        return position.compare(other)
    }

    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard
            let from = from as? TextPosition,
            let toPosition = toPosition as? TextPosition
        else {
            return 0
        }

        return toPosition.index - from.index
    }

    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
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

    public func characterRange(
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

    public func baseWritingDirection(
        for position: UITextPosition,
        in direction: UITextStorageDirection
    ) -> NSWritingDirection {
        // Numeric input should be left-to-right always.
        return .leftToRight
    }

    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        // No-op
    }

    public func firstRect(for range: UITextRange) -> CGRect {
        guard let range = range as? TextRange, !range.isEmpty else {
            return .zero
        }

        // This method should return a rectangle that contains the digit views that
        // fall inside the given TextRange. For example, a [0,2] TextRange should
        // return a rectangle that contains digit views 0 and 1:
        //
        // 0   1   2    3    4   5   6  <- TextPosition
        //  [*] [*] [*]   [*] [*] [*]   <- UI
        //   0   1   2     3   4   5    <- DigitView index
        // ^       ^
        // |_______|                    <- [0,2] TextRange

        let firstDigitView = digitViews[clampIndex(range._start.index)]
        let secondDigitView = digitViews[clampIndex(range._end.index - 1)]

        let firstRect = firstDigitView.convert(firstDigitView.bounds, to: self)
        let secondRect = secondDigitView.convert(secondDigitView.bounds, to: self)

        return firstRect.union(secondRect)
    }

    public func caretRect(for position: UITextPosition) -> CGRect {
        guard let position = position as? TextPosition else {
            return .zero
        }

        let digitView = digitViews[clampIndex(position.index)]
        return digitView.convert(digitView.caretRect, to: self)
    }

    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // No text-selection
        return []
    }

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        return closestPosition(to: point, within: textStorage.extent)
    }

    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        guard
            let range = range as? TextRange,
            let digitView = hitTest(point, with: nil) as? DigitView,
            let index = digitViews.firstIndex(of: digitView)
        else {
            return nil
        }

        return range.contains(index) ? TextPosition(index) : nil
    }

    public func characterRange(at point: CGPoint) -> UITextRange? {
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
            // Color is hardcoded for now, as it's not semantically supported by ElementsUI
            // TODO(bmelts): Should this be a theme color with a low alpha component?
            static let dotColor: UIColor = .dynamic(
                light: UIColor(red: 0.922, green: 0.933, blue: 0.945, alpha: 1.0),
                dark: UIColor(red: 0.471, green: 0.471, blue: 0.502, alpha: 0.36)
            )
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

        private let theme: ElementsUITheme

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
            label.textColor = theme.colors.textFieldText
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

        init(theme: ElementsUITheme) {
            self.theme = theme
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
            borderLayer.backgroundColor = theme.colors.background.cgColor
            borderLayer.borderColor = theme.colors.border.cgColor
            dot.backgroundColor = Constants.dotColor.cgColor
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
