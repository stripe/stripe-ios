//
//  CheckboxButton.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 12/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class CheckboxButton: UIControl {
    // MARK: - Properties
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = CompatibleColor.secondaryLabel
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.numberOfLines = 2
        label.isAccessibilityElement = false
        return label
    }()
    private lazy var checkbox: CheckBox = {
        let checkbox = CheckBox()
        checkbox.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        checkbox.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        checkbox.backgroundColor = .clear
        checkbox.isSelected = true
        return checkbox
    }()
    override var isSelected: Bool {
        didSet {
            checkbox.isSelected = isSelected
        }
    }
    override var isEnabled: Bool {
        didSet {
            checkbox.isUserInteractionEnabled = isEnabled
            label.isUserInteractionEnabled = isEnabled
        }
    }

    // MARK: - Initializers
    init(text: String) {
        super.init(frame: .zero)
        accessibilityLabel = text
        label.text = text

        let stack = UIStackView(arrangedSubviews: [checkbox, label])
        stack.spacing = 4
        addAndPinSubview(stack)

        let didTapGestureRecognizer = UITapGestureRecognizer(
            target: self, action: #selector(didTap))
        addGestureRecognizer(didTapGestureRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {
        isSelected.toggle()
        sendActions(for: .touchUpInside)
    }
}

// MARK: - CheckBox
class CheckBox: UIView {
    var isSelected: Bool = false {
        didSet {
            setNeedsDisplay()
        }
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
            STPInputFormColors.backgroundColor.setFill()
        } else {
            STPInputFormColors.disabledBackgroundColor.setFill()
        }
        borderPath.fill()
        STPInputFormColors.outlineColor.setStroke()
        borderPath.stroke()

        if isSelected {
            let checkmarkPath = UIBezierPath()
            checkmarkPath.move(to: CGPoint(x: borderRect.minX + 4, y: borderRect.minY + 6))
            checkmarkPath.addLine(
                to: CGPoint(x: borderRect.minX + 4 + 4, y: borderRect.minY + 6 + 4))
            checkmarkPath.addLine(to: CGPoint(x: borderRect.maxX + 1, y: borderRect.minY - 1))
            checkmarkPath.lineCapStyle = .round
            checkmarkPath.lineWidth = 2
            if isUserInteractionEnabled {
                STPInputFormColors.textColor.setStroke()
            } else {
                STPInputFormColors.disabledTextColor.setStroke()
            }
            checkmarkPath.stroke()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 20, height: 20)
    }
}
