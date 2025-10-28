//
//  ConnectActivityIndicator.swift
//  StripeConnect
//
//  Created by Chris Mays on 3/24/25.
//

import UIKit

/// A custom replacement for `UIActivityIndicatorView`.
/// • Matches the loading indicator used in connect embed
/// • Uses time to match movement between native and web for a seamless transition.
/// For internal SDK use only
@objc(STP_Internal_ConnectActivityIndicator)
@_spi(STP) public final class ConnectActivityIndicator: UIView {

    #if DEBUG
    /// Disables animation. This should be only be modified for snapshot tests.
    public static var isAnimationEnabled = true
    #endif

    struct Constants {
        /// Animation speed in revolutions per second
        static let animationSpeed: Double = 0.7
        static let animationKey: String = "spin"
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

    private let radius = 10.0

    private let thickness = 1.8

    private lazy var cometLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.path = makeArcPath(radius: radius, startAngle: 0.6, endAngle: 1.25)
        shape.lineWidth = thickness
        shape.lineCap = .round
        shape.strokeColor = UIColor.green.cgColor
        shape.fillColor = UIColor.clear.cgColor
        return shape
    }()

    private var contentLayer: CALayer {
        return cometLayer
    }

    public override var intrinsicContentSize: CGSize {
        let size: CGFloat = radius * 2
        return CGSize(width: size, height: size)
    }

    /// Creates a new activity indicator.
    public init() {
        super.init(frame: .zero)
        layer.addSublayer(contentLayer)

        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        setContentHuggingPriority(.defaultHigh, for: .vertical)

        updateVisibility()
        updateColor()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
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

#if !os(visionOS)
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
#if !os(visionOS)
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

public extension ConnectActivityIndicator {

    func startAnimating() {
        defer {
            isAnimating = true
            updateVisibility()
        }

        #if DEBUG
        guard ConnectActivityIndicator.isAnimationEnabled else { return }
        #endif
        let millisecondsPerRotation = Constants.animationSpeed * 1000
        let currentTimeMillis = Date().timeIntervalSince1970 * 1000
        let initialRotation = Float.pi * Float((currentTimeMillis.truncatingRemainder(dividingBy: millisecondsPerRotation)) / millisecondsPerRotation)

        // Apply initial rotation
        contentLayer.transform = CATransform3DMakeRotation(CGFloat(initialRotation), 0, 0, 1)

        // Add the continuous rotation animation
        let rotatingAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotatingAnimation.byValue = 2 * Float.pi
        rotatingAnimation.duration = Constants.animationSpeed
        rotatingAnimation.isAdditive = true
        rotatingAnimation.repeatCount = .infinity

        // Make sure animation starts from the current time-based position
        rotatingAnimation.beginTime = CACurrentMediaTime()
        contentLayer.add(rotatingAnimation, forKey: Constants.animationKey)
    }

    func stopAnimating() {
        contentLayer.removeAnimation(forKey: Constants.animationKey)

        isAnimating = false
        updateVisibility()
    }
}

// MARK: - Private methods

private extension ConnectActivityIndicator {

    func updateColor() {
        cometLayer.strokeColor = tintColor.cgColor
    }

    @objc
    func applicationWillEnterForeground() {
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
