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

        static let consentTopPadding: CGFloat = 36
        static let consentTextStyle = UIFont.TextStyle.footnote
        static var consentHTMLStyle: HTMLStyle {
            let boldFont = IdentityUI.preferredFont(forTextStyle: consentTextStyle, weight: .bold)
            return .init(
                bodyFont: IdentityUI.preferredFont(forTextStyle: consentTextStyle),
                h1Font: boldFont,
                h2Font: boldFont,
                h3Font: boldFont,
                h4Font: boldFont,
                h5Font: boldFont,
                h6Font: boldFont,
                isLinkUnderlined: false
            )
        }

        static var consentCheckboxTheme: ElementsUITheme {
            var theme = ElementsUITheme.default
            theme.colors.bodyText = IdentityUI.textColor
            theme.colors.secondaryText = IdentityUI.textColor
            return theme
        }
    }

    struct ViewModel {
        enum State {
            /// Display an empty container when waiting for camera permission prompt
            case blank
            /// Live video feed from the camera while taking selfies
            case videoPreview(CameraSessionProtocol)
            /// Display scanned selfie images
            case scanned([UIImage], consentHTMLText: String, consentHandler: (Bool) -> Void, openURLHandler: (URL) -> Void)
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

    // MARK: - Properties

    private let vStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Styling.labelBottomPadding
        return stackView
    }()

    // MARK: Instructions
    private let instructionLabelView = BottomAlignedLabel()

    // MARK: Camera Preview
    private let previewContainerView = CameraPreviewContainerView()

    /// Camera preview
    private let cameraPreviewView = CameraPreviewView()

    // MARK: Scanned Images
    
    /// Horizontal stack view of scanned images
    private let scannedImageHStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Styling.scannedImageSpacing
        return stackView
    }()

    private let scannedImageScrollView = UIScrollView()

    // MARK: Consent

    private lazy var consentCheckboxButton: CheckboxButton = {
        let checkbox = CheckboxButton(theme: Styling.consentCheckboxTheme)
        checkbox.isSelected = false
        checkbox.addTarget(self, action: #selector(didToggleConsent), for: .touchUpInside)
        checkbox.delegate = self
        return checkbox
    }()

    /// Called when the user taps the consent checkbox
    private var consentHandler: ((Bool) -> Void)?

    /// Called when the user taps on a link in the consent text
    private var openURLHandler: ((URL) -> Void)?

    /// Cache of the consent text from the viewModel so we can rebuild the
    /// attributed string when font traits change
    private var consentHTMLText: String?

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
        consentCheckboxButton.isHidden = true

        switch viewModel.state {
        case .blank:
            previewContainerView.isHidden = false

        case .videoPreview(let cameraSession):
            previewContainerView.isHidden = false
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession

        case .scanned(let images, let consentText, let consentHandler, let openURLHandler):
            scannedImageScrollView.isHidden = false
            rebuildImageHStack(with: images)

            do {
                consentCheckboxButton.setAttributedText(try NSAttributedString(
                    htmlText: consentText,
                    style: Styling.consentHTMLStyle
                ))

                consentCheckboxButton.isHidden = false
                self.consentHandler = consentHandler
                self.openURLHandler = openURLHandler
                self.consentHTMLText = consentText
            } catch {
                // TODO(mludowise|IDPROD-2816): Log error if consent can't be rendered.
                // Keep the consent checkbox hidden and treat this case the same
                // as if the user did not give consent.
            }
        }
    }

    // MARK: UIView

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // NOTE: `traitCollectionDidChange` is called off the main thread when the app backgrounds
        DispatchQueue.main.async { [weak self] in
            guard let consentHTMLText = self?.consentHTMLText else { return }
            do {
                // Recompute attributed text with updated font sizes
                self?.consentCheckboxButton.setAttributedText(try NSAttributedString(
                    htmlText: consentHTMLText,
                    style: Styling.consentHTMLStyle
                ))
            } catch {
                // Ignore errors thrown. This means the font size won't update,
                // but the text should still display if an error wasn't already
                // thrown from `configure`.
            }
        }
    }
}

private extension SelfieScanningView {
    func installViews() {
        addAndPinSubview(vStack)

        vStack.addArrangedSubview(instructionLabelView)
        vStack.addArrangedSubview(previewContainerView)
        vStack.addArrangedSubview(scannedImageScrollView)
        vStack.addArrangedSubview(consentCheckboxButton)

        previewContainerView.contentView.addAndPinSubview(cameraPreviewView)

        scannedImageScrollView.addAndPinSubview(scannedImageHStack)
    }

    func installConstraints() {
        scannedImageHStack.translatesAutoresizingMaskIntoConstraints = false
        scannedImageScrollView.setContentHuggingPriority(.required, for: .horizontal)

        vStack.setCustomSpacing(Styling.consentTopPadding, after: scannedImageScrollView)

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

    @objc func didToggleConsent() {
        consentHandler?(consentCheckboxButton.isSelected)
    }
}

// MARK: - CheckboxButton
extension SelfieScanningView: CheckboxButtonDelegate {
    func checkboxButton(_ checkboxButton: CheckboxButton, shouldOpen url: URL) -> Bool {
        openURLHandler?(url)
        return false
    }
}
