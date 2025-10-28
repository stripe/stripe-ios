//
//  LinkSeparatorView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 4/23/25.
//

import UIKit

class LinkSeparatorView: UIView {
    private let separatorHeight: CGFloat = 0.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        self.backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(separatorHeight)
        context.setStrokeColor(UIColor.linkBorderDefault.cgColor)
        context.move(to: CGPoint(x: 0, y: bounds.height - (separatorHeight/2)))
        context.addLine(to: CGPoint(x: bounds.width, y: bounds.height - (separatorHeight/2)))
        context.strokePath()
    }

    override var intrinsicContentSize: CGSize {
        // Fractional points can cause unpredictable layouts so round up to the nearest point
        CGSize(width: UIView.noIntrinsicMetric, height: ceil(separatorHeight))
    }
}
