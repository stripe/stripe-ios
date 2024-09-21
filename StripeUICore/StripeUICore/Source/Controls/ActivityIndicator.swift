//
//  ActivityIndicator.swift
//  StripeUICore
//
//  Created by Ramon Torres on 12/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// A custom replacement for `UIActivityIndicatorView`.
/// For internal SDK use only
@objc(STP_Internal_ActivityIndicator)
@_spi(STP) public final class ActivityIndicator: UIView {

    #if DEBUG
    /// Disables animation. This should be only be modified for snapshot tests.
    public static var isAnimationEnabled = true
    #endif

    struct Constants {
        /// Animation speed in revolutions per second
        static let animationSpeed: Double = 1.8
        static let animationKey: String = "spin"
    }

    /// Size of the activity indicator.
    public enum Size {
        /// The default size of an activity indicator (20x20).
        case medium
        /// A large activity indicator (37x37).
        case large
    }

    /// If `true`, the activity indicator will hide itself when not animating.
    public var hidesWhenStopped: Bool = true {
        didSet {
            if hidesWhenStopped {
                updateVisibility()
            } else {
                isHidden = false
            }
        }
    }

    /// The color of the activity indicator.
    public var color: UIColor {
        get {
            return tintColor
        }
        set {
            tintColor = newValue
        }
    }

    public private(set) var isAnimating: Bool = false

    private let size: Size

    private var radius: CGFloat {
        switch size {
        case .medium:
            return 8
        case .large:
            return 14.5
        }
    }

    private var thickness: CGFloat {
        switch size {
        case .medium:
            return 2
        case .large:
            return 4
        }
    }

    private lazy var cometLayer: CAGradientLayer = {
        let shape = CAShapeLayer()
        shape.path = makeArcPath(radius: radius, startAngle: 0.05, endAngle: 0.95)
        shape.lineWidth = thickness
        shape.lineCap = .round
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.type = .conic
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.contentsGravity = .center
        gradientLayer.mask = shape
        return gradientLayer
    }()

    private var contentLayer: CALayer {
        return cometLayer
    }

    public override var intrinsicContentSize: CGSize {
        let size: CGFloat = (radius + thickness) * 2
        return CGSize(width: size, height: size)
    }

    public convenience init() {
        self.init(size: .medium)
    }

    /// Creates a new activity indicator.
    /// - Parameter size: Size of the activity indicator.
    public init(size: Size) {
        self.size = size
        super.init(frame: .zero)
        layer.addSublayer(contentLayer)

        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)

        updateVisibility()
        updateColor()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground(_:)),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColor()
    }

#if !canImport(CompositorServices)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColor()
    }
#endif

    public override func layoutSubviews() {
        super.layoutSubviews()

        CATransaction.begin()
        // `bounds` and `position` are both animatable. Disable actions to turn off
        // implicit animations when updating them.
        CATransaction.setDisableActions(true)

        contentLayer.bounds = CGRect(origin: .zero, size: intrinsicContentSize)
        contentLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)

        CATransaction.commit()
    }

    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if let window = newWindow {
            contentLayer.shouldRasterize = true
#if !canImport(CompositorServices)
            contentLayer.rasterizationScale = window.screen.scale
#endif
        }

        if isAnimating {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
}

// MARK: - Methods

public extension ActivityIndicator {

    func startAnimating() {
        defer {
            isAnimating = true
            updateVisibility()
        }

        #if DEBUG
        guard ActivityIndicator.isAnimationEnabled else { return }
        #endif

        let rotatingAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotatingAnimation.byValue = 2 * Float.pi
        rotatingAnimation.duration = 1 / Constants.animationSpeed
        rotatingAnimation.isAdditive = true
        rotatingAnimation.repeatCount = .infinity
        contentLayer.add(rotatingAnimation, forKey: Constants.animationKey)
    }

    func stopAnimating() {
        contentLayer.removeAnimation(forKey: Constants.animationKey)

        isAnimating = false
        updateVisibility()
    }
}

// MARK: - Private methods

private extension ActivityIndicator {

    func updateColor() {
        // Tint color gradient from 0% to 100% alpha
        cometLayer.colors = [
            tintColor.withAlphaComponent(0).cgColor,
            tintColor.cgColor,
        ]
    }

    @objc
    func applicationWillEnterForeground(_ notification: Notification) {
        if isAnimating {
            // Resume animations
            startAnimating()
        }
    }

    func updateVisibility() {
        if hidesWhenStopped {
            isHidden = !isAnimating
        }
    }

    /// Creates an path containing an arc shape of a given radius and angles.
    ///
    /// Angles must be expressed in turns.
    ///
    /// <https://en.wikipedia.org/wiki/Turn_(angle)>
    ///
    /// - Parameters:
    ///   - radius: Arc radius.
    ///   - startAngle: Start angle.
    ///   - endAngle: End angle.
    /// - Returns: Arc path.
    func makeArcPath(radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat) -> CGPath {
        let path = CGMutablePath()

        let center = CGPoint(
            x: intrinsicContentSize.width / 2,
            y: intrinsicContentSize.height / 2
        )

        path.addArc(
            center: center,
            radius: radius,
            startAngle: CGFloat.pi * 2 * startAngle,
            endAngle: CGFloat.pi * 2 * endAngle,
            clockwise: false
        )

        return path
    }
}
