//
//  SelfieScanningView.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 4/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeUICore
import UIKit

/// Displays instructional text and either a camera preview or scanned selfie
/// images and consent text to the user.
final class SelfieScanningView: UIView {
    struct Styling {
        static let contentInsets = IdentityFlowView.Style.defaultContentViewInsets

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

        static func consentCheckboxTheme(tintColor: UIColor) -> ElementsAppearance {
            var theme = ElementsAppearance.default
            theme.colors.bodyText = IdentityUI.textColor
            theme.colors.secondaryText = IdentityUI.textColor
            theme.fonts.caption = IdentityUI.preferredFont(forTextStyle: .caption1)
            theme.fonts.footnote = IdentityUI.preferredFont(forTextStyle: .footnote)
            theme.fonts.footnoteEmphasis = IdentityUI.preferredFont(
                forTextStyle: .footnote,
                weight: .medium
            )
            theme.colors.primary = tintColor
            return theme
        }
    }

    struct ViewModel {
        enum StatusText {
            case holdStill
            case uploading

            var text: String {
                switch self {
                case .holdStill:
                    return STPLocalizedString(
                        "Hold still",
                        "Status text displayed over the selfie viewfinder while capturing selfies"
                    )
                case .uploading:
                    return STPLocalizedString(
                        "Uploading",
                        "Status text displayed over the blurred selfie while uploading"
                    )
                }
            }
        }

        enum State {
            /// Display an empty container when waiting for camera permission prompt
            case blank
            /// Live video feed from the camera while taking selfies
            case videoPreview(
                CameraSessionProtocol,
                showFlashAnimation: Bool,
                statusText: StatusText?
            )
            /// Display scanned selfie images
            case scanned(
                [UIImage],
                consentHTMLText: String,
                consentHandler: (Bool) -> Void,
                openURLHandler: (URL) -> Void,
                retakeSelfieHandler: () -> Void
            )
            case saving(UIImage, statusText: StatusText)
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
        stackView.alignment = .fill
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

    private let capturedImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        imageView.isAccessibilityElement = true
        imageView.accessibilityLabel = STPLocalizedString(
            "Selfie",
            "Accessibility label of captured selfie images"
        )
        return imageView
    }()

    private let capturedImageBlurView: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        blurView.isHidden = true
        return blurView
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.adjustsFontForContentSizeCategory = true
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.35
        return label
    }()

    private let statusLabelContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(
            red: 0x21 / 255,
            green: 0x25 / 255,
            blue: 0x2C / 255,
            alpha: 0.6
        )
        view.layer.cornerRadius = 8
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
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
    private(set) lazy var retakeSelfieButton: Button = {
        var retakeSelfieButtonConfiguration = Button.Configuration.plain()
        retakeSelfieButtonConfiguration.font = IdentityUI.instructionsFont
        let retakeSelfieButton = Button(configuration: retakeSelfieButtonConfiguration, title: STPLocalizedString(
            "Retake Photos",
            "Button text displayed to the user to retake photo"
        ))
        retakeSelfieButton.addTarget(self, action: #selector(didTapRetakeSelfie), for: .touchUpInside)
        return retakeSelfieButton
    }()

    private(set) lazy var retakeSelfieIcon: UIImageView = {
        let icon = UIImageView(image: Image.iconCamera.makeImage(template: true).withTintColor(IdentityUI.iconColor))
        icon.contentMode = .scaleAspectFit
        return icon
    }()

    private(set) lazy var retakeSelfieStack: UIStackView = {
        let stack = UIStackView(
            arrangedSubviews: [retakeSelfieIcon, retakeSelfieButton]
        )
        stack.axis = .horizontal
        stack.spacing = 8

        return stack
    }()

    private(set) lazy var consentCheckboxButton: CheckboxButton = {
        let checkbox = CheckboxButton(theme: Styling.consentCheckboxTheme(tintColor: tintColor))
        checkbox.isSelected = false
        checkbox.addTarget(self, action: #selector(didToggleConsent), for: .touchUpInside)
        checkbox.delegate = self
        return checkbox
    }()

    /// Called when the user taps the consent checkbox
    private var consentHandler: ((Bool) -> Void)?

    /// Called when the user taps on a link in the consent text
    private var openURLHandler: ((URL) -> Void)?

    /// Called when the user taps on retake selfie button
    private var retakeSelfieHandler: (() -> Void)?

    // MARK: Init

    init() {
        super.init(frame: .zero)
        accessibilityTraits = .updatesFrequently
        installViews()
        installConstraints()
    }

    required init(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Configure

    func configure(with viewModel: ViewModel, sheetController: VerificationSheetControllerProtocol?) {

        instructionLabelView.configure(from: viewModel.instructionalLabelViewModel)

        let isCurrentlyShowingScanned = !scannedImageScrollView.isHidden

        // Reset values
        cameraPreviewView.isHidden = true
        capturedImageView.isHidden = true
        capturedImageView.image = nil
        capturedImageBlurView.isHidden = true
        statusLabelContainerView.isHidden = true
        previewContainerView.isHidden = true
        scannedImageScrollView.isHidden = true

        switch viewModel.state {
        case .blank:
            retakeSelfieStack.isHidden = true
            consentCheckboxButton.isHidden = true
            retakeSelfieStack.isHidden = true
            previewContainerView.isHidden = false

        case .videoPreview(let cameraSession, let showFlashAnimation, let statusText):
            retakeSelfieStack.isHidden = true
            consentCheckboxButton.isHidden = true
            previewContainerView.isHidden = false
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession
            if let statusText {
                configureStatusLabel(statusText)
            }
            if showFlashAnimation {
                animateFlash()
            }

        case .scanned(let images, let consentText, let consentHandler, let openURLHandler, let retakeSelfieHandler):
            scannedImageScrollView.isHidden = false
            rebuildImageHStack(with: images)

            // Flash the scroll indicator if the scroll view is appearing for
            // the first time
            if !isCurrentlyShowingScanned {
                scannedImageScrollView.flashScrollIndicators()
            }

            do {
                consentCheckboxButton.setAttributedText(
                    try NSAttributedString.createHtmlString(
                        htmlText: consentText,
                        style: Styling.consentHTMLStyle
                    )
                )
                consentCheckboxButton.isEnabled = true
                retakeSelfieIcon.tintColor = tintColor
                retakeSelfieStack.isHidden = false
                retakeSelfieButton.isEnabled = true
                consentCheckboxButton.isHidden = false
                self.consentHandler = consentHandler
                self.openURLHandler = openURLHandler
                self.retakeSelfieHandler = retakeSelfieHandler
            } catch {
                // Keep the consent checkbox hidden and treat this case the same
                // as if the user did not give consent.
                if let sheetController = sheetController {
                    sheetController.analyticsClient.logGenericError(error: error, sheetController: sheetController)
                }
            }
        case .saving(let image, let statusText):
            previewContainerView.isHidden = false
            capturedImageView.image = image
            capturedImageView.isHidden = false
            capturedImageBlurView.isHidden = false
            configureStatusLabel(statusText)
            retakeSelfieStack.isHidden = true
            consentCheckboxButton.isHidden = true
        }
    }

    // MARK: UIView

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // NOTE: `traitCollectionDidChange` is called off the main thread when the app backgrounds
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.consentCheckboxButton.theme = Styling.consentCheckboxTheme(
                tintColor: self.tintColor
            )
        }
    }

    override func tintColorDidChange() {
        consentCheckboxButton.theme = Styling.consentCheckboxTheme(tintColor: tintColor)
    }
}

extension SelfieScanningView {
    fileprivate func installViews() {
        addAndPinSubview(vStack)

        vStack.addArrangedSubview(instructionLabelView)
        vStack.addArrangedSubview(previewContainerView)
        vStack.addArrangedSubview(scannedImageScrollView)
        vStack.addArrangedSubview(retakeSelfieStack)
        vStack.addArrangedSubview(consentCheckboxButton)

        previewContainerView.contentView.addAndPinSubview(cameraPreviewView)
        previewContainerView.contentView.addAndPinSubview(capturedImageView)
        previewContainerView.contentView.addAndPinSubview(capturedImageBlurView)
        previewContainerView.contentView.addAndPinSubview(flashOverlayView)
        previewContainerView.contentView.addSubview(statusLabelContainerView)
        statusLabelContainerView.addAndPinSubview(
            statusLabel,
            insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        )

        // Add some bottom margin so the scroll indicator doesn't overlay on
        // top of the scanned images
        scannedImageScrollView.addAndPinSubview(
            scannedImageHStack,
            insets: .init(
                top: 0,
                leading: 0,
                bottom: Styling.scannedImageScrollIndicatorMargin,
                trailing: 0
            )
        )
    }

    fileprivate func installConstraints() {
        scannedImageHStack.translatesAutoresizingMaskIntoConstraints = false
        scannedImageScrollView.setContentHuggingPriority(.required, for: .horizontal)
        previewContainerView.setContentHuggingPriority(.defaultLow, for: .vertical)
        previewContainerView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        instructionLabelView.setContentHuggingPriority(.required, for: .vertical)
        instructionLabelView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Adjusts to keep padding visually the same while accounting for scroll
        // indicator margin
        vStack.setCustomSpacing(
            Styling.consentTopPadding - Styling.scannedImageScrollIndicatorMargin,
            after: scannedImageScrollView
        )

        NSLayoutConstraint.activate([
            previewContainerView.widthAnchor.constraint(
                equalTo: widthAnchor,
                constant: -(Styling.contentInsets.leading + Styling.contentInsets.trailing)
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
            }(),
            statusLabelContainerView.centerXAnchor.constraint(
                equalTo: previewContainerView.contentView.centerXAnchor
            ),
            statusLabelContainerView.bottomAnchor.constraint(
                equalTo: previewContainerView.contentView.bottomAnchor,
                constant: -40
            ),
            statusLabelContainerView.widthAnchor.constraint(
                lessThanOrEqualTo: previewContainerView.contentView.widthAnchor,
                multiplier: 0.8
            ),
        ])
    }

    fileprivate func configureStatusLabel(_ statusText: ViewModel.StatusText) {
        statusLabel.text = statusText.text
        statusLabelContainerView.isHidden = false
    }

    fileprivate func rebuildImageHStack(with images: [UIImage]) {
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
                containerView.widthAnchor.constraint(
                    equalToConstant: Styling.scannedImageSize.width
                ),
                containerView.heightAnchor.constraint(
                    equalToConstant: Styling.scannedImageSize.height
                ),
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    fileprivate func animateFlash() {
        animateFlashInDirection(forwards: true) { [weak self] _ in
            self?.animateFlashInDirection(forwards: false)
        }
    }

    fileprivate func animateFlashInDirection(
        forwards shouldAnimateForwards: Bool,
        completion: ((Bool) -> Void)? = nil
    ) {
        let options: UIView.AnimationOptions =
            shouldAnimateForwards ? [.curveEaseIn] : [.curveEaseOut]
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

    @objc fileprivate func didToggleConsent() {
        consentHandler?(consentCheckboxButton.isSelected)
    }

    @objc fileprivate func didTapRetakeSelfie() {
        retakeSelfieHandler?()
    }
}

// MARK: - CheckboxButton
extension SelfieScanningView: CheckboxButtonDelegate {
    func checkboxButton(_ checkboxButton: CheckboxButton, shouldOpen url: URL) -> Bool {
        openURLHandler?(url)
        return false
    }
}
