//
//  STPPaymentActivityIndicatorView.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

/// This class can be used wherever you'd use a `UIActivityIndicatorView` and is intended to have a similar API. It renders as a spinning circle with a gap in it, similar to what you see in the App Store app or in the Apple Pay dialog when making a purchase. To change its color, set the `tintColor` property.
public class STPPaymentActivityIndicatorView: UIView {
    /// Tell the view to start or stop spinning. If `hidesWhenStopped` is true, it will fade in/out if animated is true.
    @objc
    public func setAnimating(
        _ animating: Bool,
        animated: Bool
    ) {
        if animating == _animating {
            return
        }
        _animating = animating
        if animating {
            if hidesWhenStopped {
                UIView.animate(
                    withDuration: animated ? 0.2 : 0,
                    animations: {
                        self.alpha = 1.0
                    })
            }
            var currentRotation = Double(0)
            if let currentLayer = layer.presentation() {
                currentRotation = Double(
                    truncating: (currentLayer.value(forKeyPath: "transform.rotation.z") as! NSNumber)
                )
            }
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.fromValue = NSNumber(value: Float(currentRotation))
            let toValue = NSNumber(value: currentRotation + 2 * Double.pi)
            animation.toValue = toValue
            animation.duration = 1.0
            animation.repeatCount = Float.infinity
            layer.add(animation, forKey: "rotation")
        } else {
            if hidesWhenStopped {
                UIView.animate(
                    withDuration: animated ? 0.2 : 0,
                    animations: {
                        self.alpha = 0.0
                    })
            }
        }
    }

    private var _animating = false
    /// Whether or not the view is animating.
    @objc public var animating: Bool {
        get {
            _animating
        }
        set(animating) {
            setAnimating(animating, animated: false)
        }
    }

    private var _hidesWhenStopped = true
    /// If true, the view will hide when it is not spinning. Default is true.
    @objc public var hidesWhenStopped: Bool {
        get {
            _hidesWhenStopped
        }
        set(hidesWhenStopped) {
            _hidesWhenStopped = hidesWhenStopped
            if !animating && hidesWhenStopped {
                alpha = 0
            } else {
                alpha = 1
            }
        }
    }
    private weak var indicatorLayer: CAShapeLayer?

    /// :nodoc:
    @objc override init(frame: CGRect) {
        var initialFrame = frame
        if initialFrame.isEmpty {
            initialFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: 40, height: 40)
        }
        super.init(frame: initialFrame)
        backgroundColor = UIColor.clear
        let layer = CAShapeLayer()
        layer.backgroundColor = UIColor.clear.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = tintColor.cgColor
        layer.strokeStart = 0
        layer.lineCap = .round
        layer.strokeEnd = 0.75
        layer.lineWidth = 2.0
        indicatorLayer = layer
        self.layer.addSublayer(layer)
        alpha = 0
    }

    /// :nodoc:
    @objc public override var tintColor: UIColor! {
        get {
            return super.tintColor
        }
        set(tintColor) {
            super.tintColor = tintColor
            indicatorLayer?.strokeColor = tintColor.cgColor
        }
    }

    /// :nodoc:
    @objc
    public override func layoutSubviews() {
        super.layoutSubviews()
        var bounds = self.bounds
        bounds.size.width = CGFloat(min(bounds.size.width, bounds.size.height))
        bounds.size.height = bounds.size.width
        let path = UIBezierPath(ovalIn: bounds)
        indicatorLayer?.path = path.cgPath
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
