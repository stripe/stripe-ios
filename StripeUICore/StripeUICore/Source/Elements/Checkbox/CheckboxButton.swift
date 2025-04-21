//
//  CheckboxButton.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 12/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
import UIKit

@_spi(STP) public protocol CheckboxButtonDelegate: AnyObject {
    /// Return `true` to open the URL in the device's default browser.
    /// Return `false` to custom handle the URL.
    func checkboxButton(_ checkboxButton: CheckboxButton, shouldOpen url: URL) -> Bool
}

/// For internal SDK use only
@objc(STP_Internal_CheckboxButton)
@_spi(STP) public class CheckboxButton: UIControl {
    // MARK: - Properties

    public weak var delegate: CheckboxButtonDelegate?

    private var font: UIFont {
        return theme.fonts.footnote
    }

    private var emphasisFont: UIFont {
        return theme.fonts.footnoteEmphasis
    }

    private lazy var textView: UITextView = {
        let textView = LinkOpeningTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = nil
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = self
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var checkbox: CheckBox = {
        let checkbox = CheckBox(theme: theme)
        checkbox.isSelected = true
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        return checkbox
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [textView, descriptionLabel])
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    /// Aligns the checkbox vertically to the first baseline of `label`.
    private lazy var checkboxAlignmentConstraint: NSLayoutConstraint = {
        return checkbox.centerYAnchor.constraint(
            equalTo: textView.firstBaselineAnchor,
            constant: 0
        )
    }()

    public override var isSelected: Bool {
        didSet {
            if isSelected {
                accessibilityTraits.update(with: .selected)
            } else {
                accessibilityTraits.remove(.selected)
            }
            checkbox.isSelected = isSelected
        }
    }

    public override var isEnabled: Bool {
        didSet {
            checkbox.isUserInteractionEnabled = isEnabled
            textView.isUserInteractionEnabled = isEnabled
        }
    }

    public private(set) var hasReceivedTap: Bool = false

    public override var isHidden: Bool {
        didSet {
            checkbox.setNeedsDisplay()
            setNeedsDisplay()
        }
    }

    public var theme: ElementsAppearance {
        didSet {
            checkbox.theme = theme
            updateLabels()
        }
    }

    // MARK: - Initializers

    public init(description: String? = nil, theme: ElementsAppearance = .default) {
        self.theme = theme
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityHint = description
        accessibilityTraits = UISwitch().accessibilityTraits

        descriptionLabel.text = description

        setupUI()

        let didTapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didTap))
        addGestureRecognizer(didTapGestureRecognizer)
    }

    public convenience init(text: String, description: String? = nil, theme: ElementsAppearance = .default) {
        self.init(description: description, theme: theme)
        setText(text)
    }

    public convenience init(attributedText: NSAttributedString, description: String? = nil, theme: ElementsAppearance = .default) {
        self.init(description: description, theme: theme)
        setAttributedText(attributedText)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        // Preferred max width sometimes is off when changing font size
        descriptionLabel.preferredMaxLayoutWidth = stackView.bounds.width
        textView.invalidateIntrinsicContentSize()
    }

#if !canImport(CompositorServices)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabels()
    }
#endif

    public func setText(_ text: String) {
        textView.text = text
        updateLabels()
        updateAccessibility()
    }

    public func setAttributedText(_ attributedText: NSAttributedString) {
        textView.attributedText = attributedText
        updateLabels()
        updateAccessibility()
    }

    private func setupUI() {
        addSubview(checkbox)
        addSubview(stackView)

        let minimizeHeight = stackView.heightAnchor.constraint(equalTo: heightAnchor)
        minimizeHeight.priority = .defaultLow
        NSLayoutConstraint.activate([
            // Checkbox
            checkboxAlignmentConstraint,
            checkbox.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            checkbox.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            checkbox.leadingAnchor.constraint(equalTo: leadingAnchor),

            // Stack view
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: checkbox.trailingAnchor, constant: 6),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            minimizeHeight,
        ])
    }

    @objc
    private func didTap() {
        hasReceivedTap = true
        isSelected.toggle()
        sendActions(for: .touchUpInside)
    }

    private func updateLabels() {
        let hasDescription = descriptionLabel.text != nil

        let textFont =  hasDescription ? emphasisFont : font
        textView.font = textFont
        textView.textColor = hasDescription ? theme.colors.bodyText : theme.colors.secondaryText

        descriptionLabel.font = font
        descriptionLabel.isHidden = !hasDescription
        descriptionLabel.textColor = theme.colors.secondaryText

        // Align checkbox to center of first line of text. The center of the checkbox is already
        // pinned to the first baseline via a constraint, so we just need to calculate
        // the offset from baseline to line center, and apply the offset to the constraint.
        let baselineToLineCenterOffset = (textFont.ascender + textFont.descender) / 2
        checkboxAlignmentConstraint.constant = -baselineToLineCenterOffset
    }

    private func updateAccessibility() {
        // Copy the text view's accessibilityValue which will describe any links
        // contained in the text to the user
        accessibilityLabel = textView.accessibilityValue ?? textView.text

        // If the text contains a link, allow links to be opened with the text
        // view's link rotor
        let linkRotors = textView.accessibilityCustomRotors?.filter({ $0.systemRotorType == .link }) ?? []
        accessibilityCustomRotors = linkRotors

        // iOS 13 automatically includes a hint if there is a link rotor, but
        // iOS 14+ do not so we must add one ourselves.
        if #available(iOS 14, *) {
            var hints = [descriptionLabel.text]
            if !linkRotors.isEmpty {
                hints.append(.Localized.useRotorToAccessLinks)
            }
            accessibilityHint = hints.compactMap { $0 }.joined(separator: ", ")
        }
    }

    func setUserInteraction(isUserInteractionEnabled: Bool) {
        isEnabled = isUserInteractionEnabled
        alpha = isUserInteractionEnabled ? 1.0 : 0.6

    }
}

extension CheckboxButton: EventHandler {
    public func handleEvent(_ event: STPEvent) {
        UIView.animate(withDuration: 0.2) {
            switch event {
            case .shouldDisableUserInteraction:
                self.setUserInteraction(isUserInteractionEnabled: false)
            case .shouldEnableUserInteraction:
                self.setUserInteraction(isUserInteractionEnabled: true)
            default:
                break
            }
        }
    }
}

// MARK: - UITextViewDelegate
extension CheckboxButton: UITextViewDelegate {
    #if !canImport(CompositorServices)
    // This is only used by StripeIdentity, which does not support visionOS.
    public func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        return delegate?.checkboxButton(self, shouldOpen: url) ?? true
    }
    #endif
}

// MARK: - CheckBox
/// For internal SDK use only
@objc(STP_Internal_CheckBox)
class CheckBox: UIView {
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    private var fillColor: UIColor {
        if isSelected {
            return theme.colors.primary
        }

        return theme.colors.parentBackground
    }

    var theme: ElementsAppearance {
        didSet {
            layer.applyShadow(shadow: theme.shadow)
            setNeedsDisplay()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }

    init(theme: ElementsAppearance = .default) {
        self.theme = theme
        super.init(frame: .zero)

        backgroundColor = .clear
        layer.applyShadow(shadow: theme.shadow)

        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let rect = rect.inset(by: superview!.alignmentRectInsets)
        let borderRectWidth = min(16, rect.width - 2)
        let borderRectHeight = min(16, rect.height - 2)
        let borderRect = CGRect(
            x: max(0, rect.midX - 0.5 * borderRectWidth),
            y: max(0, rect.midY - 0.5 * borderRectHeight), width: borderRectWidth,
            height: borderRectHeight)

        let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: 3)
        borderPath.lineWidth = 1
        if isUserInteractionEnabled {
            fillColor.setFill()
        } else {
            fillColor.setFill()
        }
        borderPath.fill()
        if theme.colors.border.rgba.alpha != 0 {
            theme.colors.border.setStroke()
        } else {
            // If the border is clear, fall back to secondaryText
            theme.colors.secondaryText.setStroke()
        }
        borderPath.stroke()

        if isSelected {
            let checkmarkPath = UIBezierPath()
            checkmarkPath.move(to: CGPoint(x: borderRect.minX + 3.5, y: borderRect.minY + 9))
            checkmarkPath.addLine(
                to: CGPoint(x: borderRect.minX + 3.5 + 4, y: borderRect.minY + 8 + 4))
            checkmarkPath.addLine(to: CGPoint(x: borderRect.maxX - 3, y: borderRect.minY + 4))

            checkmarkPath.lineCapStyle = .square
            checkmarkPath.lineJoinStyle = .bevel
            checkmarkPath.lineWidth = 2
            if isUserInteractionEnabled {
                fillColor.contrastingColor.setStroke()
            } else {
                fillColor.contrastingColor.disabledColor.setStroke()
            }
            checkmarkPath.stroke()
        }
    }
}
