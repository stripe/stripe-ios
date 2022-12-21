//
//  STPCardLoadingIndicator.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 8/24/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

private let kCardLoadingIndicatorDiameter: CGFloat = 14.0
private let kCardLoadingInnerCircleDiameter: CGFloat = 10.0
private let kLoadingAnimationSpinDuration: CFTimeInterval = 0.6
private let kLoadingAnimationIdentifier = "STPCardLoadingIndicator.spinning"

class STPCardLoadingIndicator: UIView {
    private var indicatorLayer: CALayer?

    override init(
        frame: CGRect
    ) {
        super.init(frame: frame)
        backgroundColor = UIColor(
            red: 79.0 / 255.0,
            green: 86.0 / 255.0,
            blue: 107.0 / 255.0,
            alpha: 1.0
        )

        // Make us a circle
        let shape = CAShapeLayer()
        let path = UIBezierPath(
            arcCenter: CGPoint(
                x: 0.5 * kCardLoadingIndicatorDiameter,
                y: 0.5 * kCardLoadingIndicatorDiameter
            ),
            radius: 0.5 * kCardLoadingIndicatorDiameter,
            startAngle: 0.0,
            endAngle: 2.0 * .pi,
            clockwise: true
        )
        shape.path = path.cgPath
        layer.mask = shape

        // Add the inner circle
        let innerCircle = CAShapeLayer()
        innerCircle.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        innerCircle.position = CGPoint(
            x: 0.5 * kCardLoadingIndicatorDiameter,
            y: 0.5 * kCardLoadingIndicatorDiameter
        )

        let indicatorPath = UIBezierPath(
            arcCenter: CGPoint(x: 0.0, y: 0.0),
            radius: 0.5 * kCardLoadingInnerCircleDiameter,
            startAngle: 0.0,
            endAngle: 9.0 * .pi / 6.0,
            clockwise: true
        )
        innerCircle.path = indicatorPath.cgPath
        innerCircle.strokeColor = UIColor(white: 1.0, alpha: 0.8).cgColor
        innerCircle.fillColor = UIColor.clear.cgColor
        layer.addSublayer(innerCircle)
        indicatorLayer = innerCircle
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: kCardLoadingIndicatorDiameter, height: kCardLoadingIndicatorDiameter)
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        return intrinsicContentSize
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        startAnimating()
    }

    func startAnimating() {
        let spinAnimation = CABasicAnimation(keyPath: "transform.rotation")
        spinAnimation.byValue = NSNumber(value: Float(2.0 * .pi))
        spinAnimation.duration = kLoadingAnimationSpinDuration
        spinAnimation.repeatCount = .infinity

        indicatorLayer?.add(spinAnimation, forKey: kLoadingAnimationIdentifier)
    }

    func stopAnimating() {
        indicatorLayer?.removeAnimation(forKey: kLoadingAnimationIdentifier)
    }

    required init?(
        coder aDecoder: NSCoder
    ) {
        super.init(coder: aDecoder)
    }
}
