//
//  SelfieScanningView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/25/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

/**
 Displays instructional text and either a camera preview or scanned selfie
 images and consent text to the user.
 */
final class SelfieScanningView: UIView {
    struct Styling {
        static let contentInsets = IdentityFlowView.Style.defaultContentViewInsets

        static let viewWidthToContainerHeightRatio = IdentityUI.documentCameraPreviewAspectRatio

        static let labelBottomPadding = IdentityUI.scanningViewLabelBottomPadding
        static let labelMinHeightNumberOfLines = IdentityUI.scanningViewLabelMinHeightNumberOfLines
        static var labelFont: UIFont {
            IdentityUI.instructionsFont
        }

        static let scannedImageSize = CGSize(width: 172, height: 198)
        static let scannedImageSpacing: CGFloat = 12
        static let scannedImageCornerRadius: CGFloat = 12
    }

    struct ViewModel {
        enum State {
            /// Display an empty container when waiting for camera permission prompt
            case blank
            /// Live video feed from the camera while taking selfies
            case videoPreview(CameraSessionProtocol)
            /// Display scanned selfie images
            case scanned([UIImage])
        }

        let state: State
        let instructionalText: String

        var instructionalLabelViewModel: BottomAlignedLabel.ViewModel {
            return .init(
                text: instructionalText,
                minNumberOfLines: Styling.labelMinHeightNumberOfLines,
                font: Styling.labelFont
            )
        }
    }

    // MARK: Views

    private let instructionLabelView = BottomAlignedLabel()

    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Styling.labelBottomPadding
        return stackView
    }()

    private let previewContainerView = CameraPreviewContainerView()

    /// Camera preview
    private let cameraPreviewView = CameraPreviewView()

    /// Horizontal stack view of scanned images
    private let scannedImageHStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Styling.scannedImageSpacing
        return stackView
    }()

    private let scannedImageScrollView = UIScrollView()


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

        instructionLabelView.configure(from: viewModel.instructionalLabelViewModel)

        // Reset values
        cameraPreviewView.isHidden = true
        previewContainerView.isHidden = true
        scannedImageScrollView.isHidden = true

        switch viewModel.state {
        case .blank:
            previewContainerView.isHidden = false

        case .videoPreview(let cameraSession):
            previewContainerView.isHidden = false
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession

        case .scanned(let images):
            scannedImageScrollView.isHidden = false
            rebuildImageHStack(with: images)
        }
    }
}

private extension SelfieScanningView {
    func installViews() {
        addAndPinSubview(vStack)

        vStack.addArrangedSubview(instructionLabelView)
        vStack.addArrangedSubview(previewContainerView)
        vStack.addArrangedSubview(scannedImageScrollView)

        previewContainerView.contentView.addAndPinSubview(cameraPreviewView)

        scannedImageScrollView.addAndPinSubview(scannedImageHStack)
    }

    func installConstraints() {
        scannedImageHStack.translatesAutoresizingMaskIntoConstraints = false
        scannedImageScrollView.setContentHuggingPriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            // Set the container to the same height as the document scanning preview, but as a square
            widthAnchor.constraint(
                equalTo: previewContainerView.widthAnchor,
                multiplier: Styling.viewWidthToContainerHeightRatio,
                constant: Styling.contentInsets.leading + Styling.contentInsets.trailing
            ),
            previewContainerView.widthAnchor.constraint(equalTo: previewContainerView.heightAnchor),

            // Set insets for label
            widthAnchor.constraint(equalTo: instructionLabelView.widthAnchor, constant: Styling.contentInsets.leading + Styling.contentInsets.trailing),

            // Make scroll view's content full-height
            scannedImageScrollView.contentLayoutGuide.topAnchor.constraint(equalTo: scannedImageScrollView.topAnchor),
            scannedImageScrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: scannedImageScrollView.bottomAnchor),

            // Set scroll view so that it will be centered if its contents don't exceed the width of the view
            scannedImageScrollView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            {
                let constraint = scannedImageScrollView.widthAnchor.constraint(greaterThanOrEqualTo: scannedImageHStack.widthAnchor)
                constraint.priority = .defaultHigh
                return constraint
            }()
        ])
    }

    func rebuildImageHStack(with images: [UIImage]) {
        // Remove old image views
        scannedImageHStack.subviews.forEach { $0.removeFromSuperview() }

        var constraints: [NSLayoutConstraint] = []

        images.forEach { image in
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = Styling.scannedImageCornerRadius
            imageView.clipsToBounds = true
            scannedImageHStack.addArrangedSubview(imageView)

            constraints += [
                imageView.widthAnchor.constraint(equalToConstant: Styling.scannedImageSize.width),
                imageView.heightAnchor.constraint(equalToConstant: Styling.scannedImageSize.height),
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }
}
