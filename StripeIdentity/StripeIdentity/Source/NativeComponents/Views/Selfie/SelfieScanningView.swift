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

        static let flashAnimationDuration: TimeInterval = 0.2
        static let flashOverlayAlpha: CGFloat = 0.8

        static let scannedImageSize = CGSize(width: 172, height: 172)
        static let scannedImageSpacing: CGFloat = 12
        static let scannedImageScrollIndicatorMargin: CGFloat = 8
        static var scannedImageScrollViewInsets: UIEdgeInsets {
            .init(
                top: 0,
                left: contentInsets.leading,
                bottom: 0,
                right: contentInsets.trailing
            )
        }

        static let consentTopPadding: CGFloat = 36
        static let consentTextStyle = UIFont.TextStyle.footnote
        static var consentHTMLStyle: HTMLStyle {
            let boldFont = IdentityUI.preferredFont(forTextStyle: consentTextStyle, weight: .bold)
            return .init(
                bodyFont: IdentityUI.preferredFont(forTextStyle: consentTextStyle),
                bodyColor: IdentityUI.textColor,
                h1Font: boldFont,
                h2Font: boldFont,
                h3Font: boldFont,
                h4Font: boldFont,
                h5Font: boldFont,
                h6Font: boldFont,
                isLinkUnderlined: false
            )
        }

        static func consentCheckboxTheme(tintColor: UIColor) -> ElementsUITheme {
            var theme = ElementsUITheme.default
            theme.colors.bodyText = IdentityUI.textColor
            theme.colors.secondaryText = IdentityUI.textColor
            theme.fonts.caption = IdentityUI.preferredFont(forTextStyle: .caption1)
            theme.fonts.footnote = IdentityUI.preferredFont(forTextStyle: .footnote)
            theme.fonts.footnoteEmphasis = IdentityUI.preferredFont(forTextStyle: .footnote, weight: .medium)
            theme.colors.primary = tintColor
            return theme
        }
    }

    struct ViewModel {
        enum State {
            /// Display an empty container when waiting for camera permission prompt
            case blank
            /// Live video feed from the camera while taking selfies
            case videoPreview(CameraSessionProtocol, showFlashAnimation: Bool)
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

    /// Creates flash animation by animating alpha
    private let flashOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.alpha = 0
        return view
    }()

    // MARK: Scanned Images

    /// Horizontal stack view of scanned images
    private let scannedImageHStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Styling.scannedImageSpacing
        return stackView
    }()

    private let scannedImageScrollView: UIScrollView = {
        let scrollView = ContentCenteringScrollView()
        // Don't clip image container shadow
        scrollView.clipsToBounds = false
        scrollView.contentInset = Styling.scannedImageScrollViewInsets
        scrollView.scrollIndicatorInsets = Styling.scannedImageScrollViewInsets
        return scrollView
    }()

    // MARK: Consent

    private(set) lazy var consentCheckboxButton: CheckboxButton = {
        let checkbox = CheckboxButton(theme: Styling.consentCheckboxTheme(tintColor: tintColor) )
        checkbox.isSelected = false
        checkbox.addTarget(self, action: #selector(didToggleConsent), for: .touchUpInside)
        checkbox.delegate = self
        return checkbox
    }()

    /// Called when the user taps the consent checkbox
    private var consentHandler: ((Bool) -> Void)?

    /// Called when the user taps on a link in the consent text
    private var openURLHandler: ((URL) -> Void)?

    // MARK: Init

    init() {
        super.init(frame: .zero)
        accessibilityTraits = .updatesFrequently
        installViews()
        installConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel, analyticsClient: IdentityAnalyticsClient?) {

        instructionLabelView.configure(from: viewModel.instructionalLabelViewModel)

        let isCurrentlyShowingScanned = !scannedImageScrollView.isHidden

        // Reset values
        cameraPreviewView.isHidden = true
        previewContainerView.isHidden = true
        scannedImageScrollView.isHidden = true

        switch viewModel.state {
        case .blank:
            consentCheckboxButton.isHidden = true
            previewContainerView.isHidden = false

        case .videoPreview(let cameraSession, let showFlashAnimation):
            consentCheckboxButton.isHidden = true
            previewContainerView.isHidden = false
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession
            if showFlashAnimation {
                animateFlash()
            }

        case .scanned(let images, let consentText, let consentHandler, let openURLHandler):
            scannedImageScrollView.isHidden = false
            rebuildImageHStack(with: images)

            // Flash the scroll indicator if the scroll view is appearing for
            // the first time
            if !isCurrentlyShowingScanned {
                scannedImageScrollView.flashScrollIndicators()
            }

            do {
                consentCheckboxButton.setAttributedText(try NSAttributedString(
                    htmlText: consentText,
                    style: Styling.consentHTMLStyle
                ))

                consentCheckboxButton.isHidden = false
                self.consentHandler = consentHandler
                self.openURLHandler = openURLHandler
            } catch {
                // Keep the consent checkbox hidden and treat this case the same
                // as if the user did not give consent.
                analyticsClient?.logGenericError(error: error)
            }
        }
    }

    // MARK: UIView

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // NOTE: `traitCollectionDidChange` is called off the main thread when the app backgrounds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.consentCheckboxButton.theme = Styling.consentCheckboxTheme(tintColor: self.tintColor)
        }
    }

    override func tintColorDidChange() {
        consentCheckboxButton.theme = Styling.consentCheckboxTheme(tintColor: tintColor)
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
        previewContainerView.contentView.addAndPinSubview(flashOverlayView)

        // Add some bottom margin so the scroll indicator doesn't overlay on
        // top of the scanned images
        scannedImageScrollView.addAndPinSubview(scannedImageHStack, insets: .init(
            top: 0,
            leading: 0,
            bottom: Styling.scannedImageScrollIndicatorMargin,
            trailing: 0
        ))
    }

    func installConstraints() {
        scannedImageHStack.translatesAutoresizingMaskIntoConstraints = false
        scannedImageScrollView.setContentHuggingPriority(.required, for: .horizontal)

        // Adjusts to keep padding visually the same while accounting for scroll
        // indicator margin
        vStack.setCustomSpacing(
            Styling.consentTopPadding - Styling.scannedImageScrollIndicatorMargin,
            after: scannedImageScrollView
        )

        NSLayoutConstraint.activate([
            // Set the container to the same height as the document scanning preview, but as a square
            widthAnchor.constraint(
                equalTo: previewContainerView.widthAnchor,
                multiplier: Styling.viewWidthToContainerHeightRatio,
                constant: Styling.contentInsets.leading + Styling.contentInsets.trailing
            ),
            previewContainerView.widthAnchor.constraint(
                equalTo: previewContainerView.heightAnchor
            ),

            // Set insets for label
            widthAnchor.constraint(
                equalTo: instructionLabelView.widthAnchor,
                constant: Styling.contentInsets.leading + Styling.contentInsets.trailing
            ),

            // Set insets for checkbox
            widthAnchor.constraint(
                equalTo: consentCheckboxButton.widthAnchor,
                constant: Styling.contentInsets.leading + Styling.contentInsets.trailing
            ),

            // Make scroll view's content full-height
            scannedImageScrollView.contentLayoutGuide.heightAnchor.constraint(
                equalTo: scannedImageScrollView.heightAnchor
            ),

            // Set scroll view so that it will be centered if its contents don't
            // exceed the width of the view
            scannedImageScrollView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            {
                let constraint = scannedImageScrollView.widthAnchor.constraint(
                    greaterThanOrEqualTo: scannedImageHStack.widthAnchor
                )
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
            imageView.isAccessibilityElement = true
            imageView.accessibilityLabel = STPLocalizedString(
                "Selfie",
                "Accessibility label of captured selfie images"
            )

            let containerView = CameraPreviewContainerView(cornerRadius: .medium)
            containerView.contentView.addAndPinSubview(imageView)
            scannedImageHStack.addArrangedSubview(containerView)

            constraints += [
                containerView.widthAnchor.constraint(equalToConstant: Styling.scannedImageSize.width),
                containerView.heightAnchor.constraint(equalToConstant: Styling.scannedImageSize.height),
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    func animateFlash() {
        animateFlashInDirection(forwards: true) { [weak self] _ in
            self?.animateFlashInDirection(forwards: false)
        }
    }

    func animateFlashInDirection(forwards shouldAnimateForwards: Bool, completion: ((Bool) -> Void)? = nil) {
        let options: UIView.AnimationOptions = shouldAnimateForwards ? [.curveEaseIn] : [.curveEaseOut]
        let alpha = shouldAnimateForwards ? Styling.flashOverlayAlpha : 0

        UIView.animate(
            withDuration: Styling.flashAnimationDuration,
            delay: 0,
            options: options,
            animations: { [weak self] in
                self?.flashOverlayView.alpha = alpha
            },
            completion: completion
        )
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
