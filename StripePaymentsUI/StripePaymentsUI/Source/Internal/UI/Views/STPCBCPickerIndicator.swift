//
//  STPCBCPickerIndicator.swift
//  StripePaymentsUI
//
//  Created by David Estes on 9/25/23.
//

import UIKit

private let kCardLoadingHeight: CGFloat = 10.0
private let kCardLoadingWidth: CGFloat = 16.0

class STPCBCPickerIndicator: UIView {
    private var indicatorLayer: CALayer?

    override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        let shapeColor = UIColor.systemGray3
        
//        UIColor(
//            red: 0.708,
//            green: 0.708,
//            blue: 0.708,
//            alpha: 1.0
//        )
//
        // Make chevron
        let shape = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: kCardLoadingWidth / 2.0, y: kCardLoadingHeight))
        path.addLine(to: CGPoint(x: kCardLoadingWidth, y: 0))

        shape.path = path.cgPath
        shape.fillColor = CGColor(gray: 0, alpha: 0)
        shape.strokeColor = shapeColor.cgColor
        shape.lineCap = .round
        shape.lineJoin = .round
        shape.lineWidth = 2.5
        layer.addSublayer(shape)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: kCardLoadingWidth, height: kCardLoadingHeight)
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        return intrinsicContentSize
    }

    required init?(
        coder aDecoder: NSCoder
    ) {
        super.init(coder: aDecoder)
    }
}
