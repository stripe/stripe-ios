//
//  InlineComponentView.swift
//  StripeConnect
//

import UIKit

/// Sizes an inline component to its content height with Auto Layout
final class InlineComponentView: UIView {
    var contentHeight: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
    }
}
