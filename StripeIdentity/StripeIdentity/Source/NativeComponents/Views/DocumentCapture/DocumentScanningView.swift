//
//  DocumentScanningView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 2/8/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

final class DocumentScanningView: UIView {
    struct Styling {
        static let scannedOverlayColor = CompatibleColor.systemBackground.withAlphaComponent(0.7)
        static let scannedOverlayImage = Image.iconCheckmark92

        static let containerAspectRatio = IdentityUI.documentCameraPreviewAspectRatio

        static let cutoutOverlayColor = UIColor(red: 0.412, green: 0.451, blue: 0.525, alpha: 1)
        static let cutoutCornerRadius: CGFloat = 12
        static let cutoutAspectRatio: CGFloat = 1.5 // 3:2
        static let cutoutBorderWidth: CGFloat = 4
        static let cutoutBorderStaticColor = UIColor.white
        static let cutoutBorderAnimatedColor1 = IdentityUI.stripeBlurple
        static let cutoutBorderAnimatedColor2 = UIColor.white
        static let cutoutHorizontalPadding: CGFloat = 16
    }

    enum ViewModel {
        case blank
        case videoPreview(CameraSessionProtocol, animateBorder: Bool)
        case scanned(UIImage)
    }

    // MARK: Views

    private let containerView = CameraPreviewContainerView()

    /// Overlay with cut out
    private lazy var cutoutOverlayView: UIView = {
        let view = UIView()
        view.layer.mask = overlayMaskLayer
        view.backgroundColor = Styling.cutoutOverlayColor
        view.layer.compositingFilter = "multiplyBlendMode"
        return view
    }()

    private let cutoutBorderView = AnimatedBorderView()
    private let cameraPreviewView = CameraPreviewView()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private let scannedOverlayIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Styling.scannedOverlayImage.makeImage(template: true)
        imageView.contentMode = .center
        imageView.backgroundColor = Styling.scannedOverlayColor
        return imageView
    }()

    // MARK: Custom Layers

    /// Mask to remove cut out from overlay
    private let overlayMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        return layer
    }()

    // MARK: Init

    init() {
        super.init(frame: .zero)
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
        scannedOverlayIconView.isHidden = true

        cameraPreviewView.isHidden = true
        cutoutOverlayView.isHidden = true
        cutoutBorderView.isHidden = true


        switch viewModel {
        case .blank:
            cutoutBorderView.isAnimating = false
            break

        case .scanned(let image):
            imageView.isHidden = false
            imageView.image = image
            scannedOverlayIconView.isHidden = false
            cutoutBorderView.isAnimating = false

        case .videoPreview(let cameraSession, let shouldAnimateBorder):
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession
            cutoutOverlayView.isHidden = false
            cutoutBorderView.isHidden = false
            cutoutBorderView.configure(with: .init(
                color1: shouldAnimateBorder ? Styling.cutoutBorderAnimatedColor1 : Styling.cutoutBorderStaticColor,
                color2: shouldAnimateBorder ? Styling.cutoutBorderAnimatedColor2 : Styling.cutoutBorderStaticColor,
                borderWidth: Styling.cutoutBorderWidth,
                cornerRadius: Styling.cutoutCornerRadius,
                isAnimating: shouldAnimateBorder
            ))
        }
    }

    // MARK: UIView

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCutoutBounds()
    }
}

// MARK: - Helpers

private extension DocumentScanningView {
    func installViews() {
        addAndPinSubview(containerView)
        containerView.contentView.addAndPinSubview(imageView)
        containerView.contentView.addAndPinSubview(scannedOverlayIconView)
        containerView.contentView.addAndPinSubview(cameraPreviewView)
        containerView.contentView.addAndPinSubview(cutoutOverlayView)
        containerView.contentView.addSubview(cutoutBorderView)
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
}
