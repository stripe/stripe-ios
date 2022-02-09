//
//  CameraScanningView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/8/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

final class CameraScanningView: UIView {
    struct Styling {
        static let backgroundColor = IdentityUI.containerColor

        static let containerShadows = [
            ShadowConfiguration(
                shadowColor: .black,
                shadowOffset: CGSize(width: 0, height: 1),
                shadowOpacity: 0.12,
                shadowRadius: 1
            ),
            ShadowConfiguration(
                shadowColor: UIColor(red: 0.235, green: 0.259, blue: 0.341, alpha: 1),
                shadowOffset: CGSize(width: 0, height: 2),
                shadowOpacity: 0.08,
                shadowRadius: 5
            )
        ]

        static let containerCornerRadius: CGFloat = 16
        static let containerAspectRatio: CGFloat = 1.25 // 5:4
        static let containerOverlayColor = UIColor(red: 0.412, green: 0.451, blue: 0.525, alpha: 1)

        static let cutoutCornerRadius: CGFloat = 12
        static let cutoutAspectRatio: CGFloat = 1.5 // 3:2
        static let cutoutBorderWidth: CGFloat = 4
        static let cutoutBorderColor = UIColor.white
        static let cutoutHorizontalPadding: CGFloat = 16
    }

    enum ViewModel {
        case blank
        case staticImage(UIImage, contentMode: UIView.ContentMode)
        case videoPreview(CameraSessionProtocol)
    }

    // MARK: Views

    /// Container for image and camera preview
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Styling.backgroundColor
        view.layer.cornerRadius = Styling.containerCornerRadius
        view.clipsToBounds = true
        return view
    }()

    /// Overlay with cut out
    private lazy var overlayView: UIView = {
        let view = UIView()
        view.layer.mask = overlayMaskLayer
        view.backgroundColor = Styling.containerOverlayColor
        view.layer.compositingFilter = "multiplyBlendMode"
        return view
    }()

    /// Border for cut out
    private let cutoutBorderView: UIView = {
        let view = UIView()
        view.layer.borderColor = Styling.cutoutBorderColor.cgColor
        view.layer.borderWidth = Styling.cutoutBorderWidth
        view.layer.cornerRadius = Styling.cutoutCornerRadius
        view.backgroundColor = nil
        return view
    }()

    private let cameraPreviewView = CameraPreviewView()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    // MARK: Custom Layers

    /// Mask to remove cut out from overlay
    private let overlayMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        return layer
    }()

    /// Shadows for this view
    private let shadowLayers: [CALayer] = Styling.containerShadows.map { config in
        let layer = CALayer()
        config.applyTo(layer: layer)
        return layer
    }

    // MARK: Init

    init() {
        super.init(frame: .zero)
        installShadowLayers()
        installViews()
        installConstraints()
    }

    convenience init(from viewModel: ViewModel) {
        self.init()
        configure(with: viewModel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel) {
        // Reset values
        imageView.isHidden = true
        imageView.image = nil
        cameraPreviewView.isHidden = true
        overlayView.isHidden = false
        cutoutBorderView.isHidden = false

        switch viewModel {
        case .blank:
            overlayView.isHidden = true
            cutoutBorderView.isHidden = true

        case .staticImage(let image, let contentMode):
            imageView.isHidden = false
            imageView.image = image
            imageView.contentMode = contentMode

        case .videoPreview(let cameraSession):
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession
        }
    }

    // MARK: UIView

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCutoutBounds()
        updateShadowBounds()
    }
}

// MARK: - Helpers

private extension CameraScanningView {
    func installShadowLayers() {
        shadowLayers.forEach { layer.addSublayer($0) }
    }

    func installViews() {
        addAndPinSubview(containerView)
        containerView.addAndPinSubview(imageView)
        containerView.addAndPinSubview(cameraPreviewView)
        containerView.addAndPinSubview(overlayView)
        containerView.addSubview(cutoutBorderView)
    }

    func installConstraints() {
        cutoutBorderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Aspect ratio of overlay
            widthAnchor.constraint(equalTo: heightAnchor, multiplier: Styling.containerAspectRatio),
            // Aspect ratio of cutout
            cutoutBorderView.widthAnchor.constraint(equalTo: cutoutBorderView.heightAnchor, multiplier: Styling.cutoutAspectRatio),
            // Horizontal insets of cutout
            cutoutBorderView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Styling.cutoutHorizontalPadding),
            cutoutBorderView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Styling.cutoutHorizontalPadding),
            // Vertically center cutout
            cutoutBorderView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func updateCutoutBounds() {
        // Compute the frame of the cut out for the new view size
        let width = bounds.width - (Styling.cutoutHorizontalPadding * 2)
        let height = width / Styling.cutoutAspectRatio
        let cutoutRect = CGRect(
            x: Styling.cutoutHorizontalPadding,
            y: (bounds.height - height) / 2,
            width: width,
            height: height
        )

        // Update the overlay path to match the size of the cut out
        let cutoutPath = UIBezierPath(
            roundedRect: cutoutRect,
            cornerRadius: Styling.cutoutCornerRadius
        )

        let path = UIBezierPath(rect: bounds)
        path.append(cutoutPath)
        overlayMaskLayer.path = path.cgPath
    }

    func updateShadowBounds() {
        shadowLayers.forEach { layer in
            layer.shadowPath = UIBezierPath(
                roundedRect: bounds,
                cornerRadius: Styling.containerCornerRadius
            ).cgPath
        }
    }
}
