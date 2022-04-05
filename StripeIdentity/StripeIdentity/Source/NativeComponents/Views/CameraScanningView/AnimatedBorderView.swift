//
//  AnimatedBorderView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/19/22.
//

import Foundation
import UIKit

final class AnimatedBorderView: UIView {

    struct Constants {
        /// Animation speed in revolutions per second
        static let animationSpeed: Double = 0.66
        static let animationKey = "spin"
    }

    #if DEBUG
    /// Disables animation. This should be only be modified for snapshot tests.
    static var isAnimationEnabled = true
    #endif

    struct ViewModel {
        let color1: UIColor
        let color2: UIColor
        let borderWidth: CGFloat
        let cornerRadius: CGFloat
        let isAnimating: Bool
    }

    // MARK: Instance Properties

    private var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.type = .conic
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 1)

        // Initialize with dummy color until view has been configured
        layer.colors = Array(repeating: UIColor.clear.cgColor, count: 4)

        layer.locations = [
            0,
            0.12,
            0.55,
            0.75,
            1
        ]
        return layer
    }()

    private let maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        return layer
    }()

    private var borderWidth: CGFloat = 0
    var isAnimating = false {
        didSet {
            guard oldValue != isAnimating else {
                return
            }

            if isAnimating {
                startAnimating()
            } else {
                stopAnimating()
            }
        }
    }

    init() {
        super.init(frame: .zero)
        layer.addSublayer(gradientLayer)
        layer.mask = maskLayer
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel) {
        gradientLayer.colors = [
            viewModel.color1.cgColor,
            viewModel.color2.withAlphaComponent(0).cgColor,
            viewModel.color2.withAlphaComponent(0).cgColor,
            viewModel.color1.cgColor,
            viewModel.color1.cgColor,
        ]
        backgroundColor = viewModel.color2
        layer.cornerRadius = viewModel.cornerRadius
        borderWidth = viewModel.borderWidth
        updateLayerBounds()
        isAnimating = viewModel.isAnimating
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayerBounds()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if let window = window {
            gradientLayer.shouldRasterize = true
            gradientLayer.rasterizationScale = window.screen.scale
        }

        if isAnimating {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
}

private extension AnimatedBorderView {
    private func updateLayerBounds() {
        // Gradient layer needs to be a square with width >= the diagonal
        // dimension of this view so there are no gaps during animation
        let dimension = sqrt(bounds.width * bounds.width + bounds.height * bounds.height)

        gradientLayer.frame = CGRect(
            x: bounds.minX + (bounds.width - dimension) / 2,
            y: bounds.minY + (bounds.height - dimension) / 2,
            width: dimension,
            height: dimension
        )

        // Update mask layer bounds
        let cutoutRect = bounds.inset(by: UIEdgeInsets(top: borderWidth, left: borderWidth, bottom: borderWidth, right: borderWidth))
        let cutoutPath = UIBezierPath(
            roundedRect: cutoutRect,
            cornerRadius: layer.cornerRadius - borderWidth
        )
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius)
        path.append(cutoutPath)
        maskLayer.path = path.cgPath
    }

    private func startAnimating() {
        #if DEBUG
        guard AnimatedBorderView.isAnimationEnabled else { return }
        #endif

        let rotatingAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotatingAnimation.byValue = 2 * Float.pi
        rotatingAnimation.duration = 1 / Constants.animationSpeed
        rotatingAnimation.isAdditive = true
        rotatingAnimation.repeatCount = .infinity
        gradientLayer.add(rotatingAnimation, forKey: Constants.animationKey)
    }

    private func stopAnimating() {
        gradientLayer.removeAnimation(forKey: Constants.animationKey)
    }
}
