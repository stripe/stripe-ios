//
//  CheckboxButton.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 12/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore

/// For internal SDK use only
@objc(STP_Internal_CheckboxButton)
@_spi(STP) public class CheckboxButton: UIControl {
    // MARK: - Properties

    private var font: UIFont {
        return theme.fonts.checkbox
    }

    private var emphasisFont: UIFont {
        return theme.fonts.checkboxEmphasis
    }

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isAccessibilityElement = false
        return label
    }()

    private lazy var checkbox: CheckBox = {
        let checkbox = CheckBox(theme: theme)
        checkbox.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        checkbox.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        checkbox.backgroundColor = .clear
        checkbox.isSelected = true
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        return checkbox
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [label, descriptionLabel])
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
            equalTo: label.firstBaselineAnchor,
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
            label.isUserInteractionEnabled = isEnabled
        }
    }
    
    public private(set) var hasReceivedTap: Bool = false

    public override var isHidden: Bool {
        didSet {
            checkbox.setNeedsDisplay()
            setNeedsDisplay()
        }
    }

    let theme: ElementsUITheme

    // MARK: - Initializers

    public init(text: String, description: String? = nil, theme: ElementsUITheme = .default) {
        self.theme = theme
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityLabel = text
        accessibilityHint = description
        accessibilityTraits = UISwitch().accessibilityTraits

        label.text = text
        descriptionLabel.text = description

        setupUI()

        let didTapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didTap))
        addGestureRecognizer(didTapGestureRecognizer)

        updateLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        // Preferred max width sometimes is off when changing font size
        label.preferredMaxLayoutWidth = stackView.bounds.width
        descriptionLabel.preferredMaxLayoutWidth = stackView.bounds.width
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLabels()
    }

    private func setupUI() {
        addSubview(checkbox)
        addSubview(stackView)

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
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor)
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

        label.font = hasDescription ? emphasisFont : font
        label.textColor = hasDescription ? theme.colors.bodyText : theme.colors.secondaryText

        descriptionLabel.font = font
        descriptionLabel.isHidden = !hasDescription
        descriptionLabel.textColor = theme.colors.secondaryText

        // Align checkbox to center of first line of text. The center of the checkbox is already
        // pinned to the first baseline via a constraint, so we just need to calculate
        // the offset from baseline to line center, and apply the offset to the contraint.
        let baselineToLineCenterOffset = (label.font.ascender + label.font.descender) / 2
        checkboxAlignmentConstraint.constant = -baselineToLineCenterOffset
    }
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
        
        return theme.colors.background
    }

    let theme: ElementsUITheme

    init(theme: ElementsUITheme) {
        self.theme = theme
        super.init(frame: .zero)
        layer.applyShadow(shadow: theme.shadow)
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
        theme.colors.border.setStroke()
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

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }
}
