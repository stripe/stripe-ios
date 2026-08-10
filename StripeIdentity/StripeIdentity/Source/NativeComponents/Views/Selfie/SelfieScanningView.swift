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
        static let preferredPreviewHeightToWidthRatio: CGFloat = 4 / 3
        static let captureGuideShadowFadeInDuration: TimeInterval = 0.6
        static let livePreviewBlurFadeInDuration: TimeInterval = 0.3
        static let livePreviewBlurFadeOutDuration: TimeInterval = 0.6
        static var livePreviewBlurEffect: UIBlurEffect {
            UIBlurEffect(style: .systemUltraThinMaterial)
        }
        /// Tint used in place of `livePreviewBlurEffect` when Reduce Transparency
        /// is enabled, since blur materials become opaque and would otherwise
        /// completely obscure the camera feed.
        static var livePreviewBlurReduceTransparencyTint: UIColor {
            UIColor.black.withAlphaComponent(0.35)
        }
        static let statusLabelFadeInDuration: TimeInterval = 0.18
        static let statusLabelFadeOutDuration: TimeInterval = 0.6
        static let turnPromptArrowAnimationDuration: TimeInterval = 0.45
        static let turnPromptArrowAnimationOffset: CGFloat = 5
        static var statusLabelFont: UIFont {
            .systemFont(ofSize: 14, weight: .medium)
        }
        static let statusLabelLineHeight: CGFloat = 18
        static func statusLabelAttributedString(_ text: String) -> NSAttributedString {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = statusLabelLineHeight
            paragraphStyle.maximumLineHeight = statusLabelLineHeight
            paragraphStyle.alignment = .center
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: statusLabelFont,
                    .foregroundColor: UIColor.white,
                    .paragraphStyle: paragraphStyle,
                ]
            )
        }
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
        enum CaptureGuideHighlight: Equatable {
            case none
            case front
            case left
            case right
        }

        enum CaptureGuideTarget: Equatable {
            case none
            case left
            case right
        }

        enum StatusText: Equatable {
            case placeFace
            case moveCloser
            case holdStill
            case lookLeft
            case lookLeftBottom
            case lookRight
            case lookRightBottom
            case capturedFront
            case capturedLeft
            case capturedRight
            case uploading

            var text: String {
                switch self {
                case .placeFace:
                    return STPLocalizedString(
                        "Place your face within the frame",
                        "Status text displayed over the selfie viewfinder while positioning a face"
                    )
                case .moveCloser:
                    return STPLocalizedString(
                        "Move closer",
                        "Status text displayed over the selfie viewfinder when a face is too far away"
                    )
                case .holdStill:
                    return STPLocalizedString(
                        "Hold still...",
                        "Status text displayed over the selfie viewfinder while capturing selfies"
                    )
                case .lookLeft,
                    .lookLeftBottom:
                    return STPLocalizedString(
                        "Turn head left",
                        "Status text displayed over the selfie viewfinder while capturing the left side of a face"
                    )
                case .lookRight,
                    .lookRightBottom:
                    return STPLocalizedString(
                        "Turn head right",
                        "Status text displayed over the selfie viewfinder while capturing the right side of a face"
                    )
                case .capturedFront:
                    return STPLocalizedString(
                        "Captured front",
                        "Status text displayed over the selfie viewfinder after capturing the front of a face"
                    )
                case .capturedLeft:
                    return STPLocalizedString(
                        "Captured left",
                        "Status text displayed over the selfie viewfinder after capturing the left side of a face"
                    )
                case .capturedRight:
                    return STPLocalizedString(
                        "Captured right",
                        "Status text displayed over the selfie viewfinder after capturing the right side of a face"
                    )
                case .uploading:
                    return STPLocalizedString(
                        "Great! Checking your images....",
                        "Status text displayed over the blurred selfie while checking uploaded selfie images"
                    )
                }
            }

            var showsActivityIndicator: Bool {
                switch self {
                case .placeFace,
                    .moveCloser,
                    .holdStill,
                    .lookLeft,
                    .lookLeftBottom,
                    .lookRight,
                    .lookRightBottom,
                    .capturedFront,
                    .capturedLeft,
                    .capturedRight:
                    return false
                case .uploading:
                    return true
                }
            }

            var isCenteredInViewfinder: Bool {
                switch self {
                case .placeFace,
                    .moveCloser,
                    .holdStill,
                    .lookLeftBottom,
                    .lookRightBottom,
                    .capturedFront,
                    .capturedLeft,
                    .capturedRight:
                    return false
                case .lookLeft,
                    .lookRight:
                    return true
                case .uploading:
                    return true
                }
            }

            var usesLivePreviewBlur: Bool {
                switch self {
                case .placeFace,
                    .moveCloser,
                    .holdStill,
                    .lookLeftBottom,
                    .lookRightBottom,
                    .lookLeft,
                    .lookRight,
                    .uploading:
                    return false
                case .capturedFront,
                    .capturedLeft,
                    .capturedRight:
                    return true
                }
            }

            var showsCenteredShadowIn3DCapture: Bool {
                switch self {
                case .holdStill,
                    .lookLeftBottom,
                    .lookRightBottom,
                    .capturedFront,
                    .capturedLeft,
                    .capturedRight:
                    return true
                case .placeFace,
                    .lookLeft,
                    .lookRight,
                    .uploading:
                    return false
                case .moveCloser:
                    return false
                }
            }

            var turnPromptArrowText: String? {
                switch self {
                case .lookLeft:
                    return "←"
                case .lookRight:
                    return "→"
                case .placeFace,
                    .moveCloser,
                    .holdStill,
                    .lookLeftBottom,
                    .lookRightBottom,
                    .capturedFront,
                    .capturedLeft,
                    .capturedRight,
                    .uploading:
                    return nil
                }
            }

            var placesTurnPromptArrowAfterText: Bool {
                return self == .lookRight
            }
        }

        enum State {
            /// Display an empty container when waiting for camera permission prompt
            case blank
            /// Live video feed from the camera while taking selfies
            case videoPreview(
                CameraSessionProtocol,
                showFlashAnimation: Bool,
                statusText: StatusText?,
                captureGuideHighlight: CaptureGuideHighlight,
                uses3DCaptureAnimations: Bool = false,
                captureGuideTarget: CaptureGuideTarget = .none,
                captureGuideProgress: CGFloat = 0
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

        init(
            state: State,
            instructionalText: String
        ) {
            self.state = state
            self.instructionalText = instructionalText
        }

        var instructionalLabelViewModel: BottomAlignedLabel.ViewModel {
            return .init(
                text: instructionalText,
                minNumberOfLines: Styling.labelMinHeightNumberOfLines,
                font: Styling.labelFont
            )
        }
    }

    private struct TurnPromptArrowConfiguration: Equatable {
        let text: String
        let placesAfterText: Bool
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
    private let previewContainerView = CameraPreviewContainerView(
        cornerRadius: .viewfinder,
        shadowStyle: .viewfinder
    )

    private let trailingTurnPromptArrowLabel: UILabel = {
        let label = UILabel()
        label.font = Styling.statusLabelFont
        label.textColor = .white
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.35
        return label
    }()

    /// Camera preview
    private let cameraPreviewView = CameraPreviewView()

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
        let blurView = UIVisualEffectView(effect: nil)
        blurView.backgroundColor = .clear
        blurView.contentView.backgroundColor = .clear
        blurView.isHidden = true
        return blurView
    }()

    private var isPreviewBlurVisible = false
    private var previewBlurAnimator: UIViewPropertyAnimator?
    private var isStatusLabelVisible = false
    private var currentTurnPromptArrowConfiguration: TurnPromptArrowConfiguration?
    private let turnPromptArrowAnimationKey = "TurnPromptArrowAnimation"

    private let captureTickMarksView: CaptureTickMarksView = {
        let view = CaptureTickMarksView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private let leadingTurnPromptArrowLabel: UILabel = {
        let label = UILabel()
        label.font = Styling.statusLabelFont
        label.textColor = .white
        label.adjustsFontForContentSizeCategory = true
        label.isHidden = true
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.35
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Styling.statusLabelFont
        label.textColor = .white
        label.adjustsFontForContentSizeCategory = true
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowOffset = CGSize(width: 0, height: 1)
        label.layer.shadowRadius = 4
        label.layer.shadowOpacity = 0.35
        return label
    }()

    private let statusActivityIndicatorView: ActivityIndicator = {
        let activityIndicatorView = ActivityIndicator(size: .medium)
        activityIndicatorView.color = .white
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.isHidden = true
        return activityIndicatorView
    }()

    private lazy var statusContentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            leadingTurnPromptArrowLabel,
            statusActivityIndicatorView,
            statusLabel,
            trailingTurnPromptArrowLabel,
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
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
        view.layer.cornerCurve = .continuous
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var statusLabelBottomConstraint = statusLabelContainerView.bottomAnchor.constraint(
        equalTo: previewContainerView.contentView.bottomAnchor,
        constant: -40
    )

    private lazy var statusLabelCenterYConstraint = statusLabelContainerView.centerYAnchor.constraint(
        equalTo: previewContainerView.contentView.centerYAnchor
    )

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
        instructionLabelView.isHidden = false
        cameraPreviewView.isHidden = true
        capturedImageView.isHidden = true
        capturedImageView.image = nil
        captureTickMarksView.isHidden = true
        statusActivityIndicatorView.stopAnimating()
        previewContainerView.isHidden = true
        scannedImageScrollView.isHidden = true

        switch viewModel.state {
        case .blank:
            setPreviewBlurVisible(false, animated: false)
            setStatusLabelVisible(false, animated: false)
            retakeSelfieStack.isHidden = true
            consentCheckboxButton.isHidden = true
            retakeSelfieStack.isHidden = true
            captureTickMarksView.setShowsCenteredShadow(false, animated: false)
            previewContainerView.isHidden = false

        case .videoPreview(
            let cameraSession,
            _,
            let statusText,
            let captureGuideHighlight,
            let uses3DCaptureAnimations,
            let captureGuideTarget,
            let captureGuideProgress
        ):
            instructionLabelView.isHidden = true
            retakeSelfieStack.isHidden = true
            consentCheckboxButton.isHidden = true
            previewContainerView.isHidden = false
            cameraPreviewView.isHidden = false
            cameraPreviewView.session = cameraSession
            let shouldBlurLivePreview = shouldBlurLivePreview(
                for: statusText,
                uses3DCaptureAnimations: uses3DCaptureAnimations
            )
            setPreviewBlurVisible(shouldBlurLivePreview, animated: true)
            captureTickMarksView.isHidden = false
            let shouldShowCenteredShadow = uses3DCaptureAnimations
                && !shouldBlurLivePreview
                && (statusText?.showsCenteredShadowIn3DCapture == true
                    || captureGuideTarget != .none
                    || captureGuideHighlight != .none)
            captureTickMarksView.setShowsCenteredShadow(
                shouldShowCenteredShadow,
                animated: true
            )
            captureTickMarksView.setUses3DCaptureAnimations(uses3DCaptureAnimations)
            captureTickMarksView.setCaptureGuideTarget(
                captureGuideTarget,
                progress: captureGuideProgress,
                animated: true
            )
            captureTickMarksView.setCaptureGuideHighlight(captureGuideHighlight, animated: true)
            if let statusText {
                configureStatusLabel(statusText, animated: true)
            } else {
                setStatusLabelVisible(false, animated: true)
            }

        case .scanned(let images, let consentText, let consentHandler, let openURLHandler, let retakeSelfieHandler):
            setPreviewBlurVisible(false, animated: false)
            setStatusLabelVisible(false, animated: false)
            captureTickMarksView.setShowsCenteredShadow(false, animated: false)
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
            instructionLabelView.isHidden = true
            captureTickMarksView.setShowsCenteredShadow(false, animated: false)
            previewContainerView.isHidden = false
            capturedImageView.image = image
            capturedImageView.isHidden = false
            setPreviewBlurVisible(true, animated: false)
            configureStatusLabel(statusText, animated: false)
            retakeSelfieStack.isHidden = true
            consentCheckboxButton.isHidden = true
        }
    }

    private func shouldBlurLivePreview(
        for statusText: ViewModel.StatusText?,
        uses3DCaptureAnimations: Bool
    ) -> Bool {
        guard let statusText else {
            return false
        }

        if uses3DCaptureAnimations {
            switch statusText {
            case .lookLeft,
                .lookRight:
                return true
            case .capturedLeft,
                .capturedRight:
                return true
            case .capturedFront:
                return false
            case .placeFace,
                .moveCloser,
                .holdStill,
                .lookLeftBottom,
                .lookRightBottom,
                .uploading:
                break
            }
        }

        return statusText.usesLivePreviewBlur
    }

    private func setPreviewBlurVisible(_ isVisible: Bool, animated: Bool) {
        guard isVisible != isPreviewBlurVisible else {
            guard !animated else {
                return
            }
            previewBlurAnimator?.stopAnimation(true)
            previewBlurAnimator = nil
            applyPreviewBlurEffect(visible: isVisible)
            capturedImageBlurView.isHidden = !isVisible
            return
        }
        let duration = isVisible
            ? Styling.livePreviewBlurFadeInDuration
            : Styling.livePreviewBlurFadeOutDuration

        previewBlurAnimator?.stopAnimation(true)
        previewBlurAnimator = nil
        isPreviewBlurVisible = isVisible
        if isVisible {
            capturedImageBlurView.isHidden = false
        }

        guard animated, window != nil else {
            applyPreviewBlurEffect(visible: isVisible)
            capturedImageBlurView.isHidden = !isVisible
            return
        }

        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            self.applyPreviewBlurEffect(visible: isVisible)
        }
        animator.addCompletion { [weak self] _ in
            guard let self = self else {
                return
            }
            self.previewBlurAnimator = nil
            if !self.isPreviewBlurVisible {
                self.capturedImageBlurView.isHidden = true
            }
        }
        previewBlurAnimator = animator
        animator.startAnimation()
    }

    private func applyPreviewBlurEffect(visible isVisible: Bool) {
        guard isVisible else {
            capturedImageBlurView.effect = nil
            capturedImageBlurView.backgroundColor = .clear
            return
        }
        if UIAccessibility.isReduceTransparencyEnabled {
            // Blur materials render as an opaque veil when Reduce Transparency
            // is enabled, completely obscuring the camera feed. Use a
            // translucent tint instead so the feed stays visible.
            capturedImageBlurView.effect = nil
            capturedImageBlurView.backgroundColor = Styling.livePreviewBlurReduceTransparencyTint
        } else {
            capturedImageBlurView.backgroundColor = .clear
            capturedImageBlurView.effect = Styling.livePreviewBlurEffect
        }
    }

    private func setStatusLabelVisible(_ isVisible: Bool, animated: Bool) {
        guard isVisible != isStatusLabelVisible else {
            guard !animated else {
                return
            }
            statusLabelContainerView.layer.removeAllAnimations()
            statusLabelContainerView.alpha = isVisible ? 1 : 0
            statusLabelContainerView.isHidden = !isVisible
            return
        }

        isStatusLabelVisible = isVisible
        if isVisible {
            statusLabelContainerView.isHidden = false
        }

        guard animated, window != nil else {
            statusLabelContainerView.alpha = isVisible ? 1 : 0
            statusLabelContainerView.isHidden = !isVisible
            return
        }

        let duration = isVisible
            ? Styling.statusLabelFadeInDuration
            : Styling.statusLabelFadeOutDuration
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState, .curveEaseInOut],
            animations: {
                self.statusLabelContainerView.alpha = isVisible ? 1 : 0
            },
            completion: { [weak self] _ in
                guard let self = self, !self.isStatusLabelVisible else {
                    return
                }
                self.statusLabelContainerView.isHidden = true
            }
        )
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
            // Re-apply in case Reduce Transparency was toggled while visible
            self.applyPreviewBlurEffect(visible: self.isPreviewBlurVisible)
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
        previewContainerView.contentView.addAndPinSubview(captureTickMarksView)
        previewContainerView.contentView.addSubview(statusLabelContainerView)
        statusLabelContainerView.addAndPinSubview(
            statusContentStackView,
            insets: .init(top: 6, leading: 8, bottom: 6, trailing: 8)
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
            {
                let constraint = previewContainerView.heightAnchor.constraint(
                    equalTo: previewContainerView.widthAnchor,
                    multiplier: Styling.preferredPreviewHeightToWidthRatio
                )
                constraint.priority = .defaultHigh
                return constraint
            }(),
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
            statusLabelBottomConstraint,
            statusLabelContainerView.widthAnchor.constraint(
                lessThanOrEqualTo: previewContainerView.contentView.widthAnchor,
                multiplier: 0.8
            ),
        ])
    }

    fileprivate func configureStatusLabel(_ statusText: ViewModel.StatusText, animated: Bool) {
        statusLabel.attributedText = Styling.statusLabelAttributedString(statusText.text)
        configureTurnPromptArrow(for: statusText)
        statusLabelBottomConstraint.isActive = !statusText.isCenteredInViewfinder
        statusLabelCenterYConstraint.isActive = statusText.isCenteredInViewfinder
        statusActivityIndicatorView.isHidden = !statusText.showsActivityIndicator
        if statusText.showsActivityIndicator {
            statusActivityIndicatorView.startAnimating()
        } else {
            statusActivityIndicatorView.stopAnimating()
        }
        setStatusLabelVisible(true, animated: animated)
    }

    private func configureTurnPromptArrow(for statusText: ViewModel.StatusText) {
        let configuration = statusText.turnPromptArrowText.map {
            TurnPromptArrowConfiguration(
                text: $0,
                placesAfterText: statusText.placesTurnPromptArrowAfterText
            )
        }
        if configuration == currentTurnPromptArrowConfiguration {
            if let configuration {
                let arrowLabel = configuration.placesAfterText
                    ? trailingTurnPromptArrowLabel
                    : leadingTurnPromptArrowLabel
                if arrowLabel.layer.animation(forKey: turnPromptArrowAnimationKey) != nil {
                    return
                }
            } else {
                return
            }
        }

        currentTurnPromptArrowConfiguration = configuration
        stopTurnPromptArrowAnimation(on: leadingTurnPromptArrowLabel)
        stopTurnPromptArrowAnimation(on: trailingTurnPromptArrowLabel)

        guard let configuration else {
            leadingTurnPromptArrowLabel.isHidden = true
            trailingTurnPromptArrowLabel.isHidden = true
            return
        }

        let arrowLabel = configuration.placesAfterText
            ? trailingTurnPromptArrowLabel
            : leadingTurnPromptArrowLabel
        let hiddenArrowLabel = configuration.placesAfterText
            ? leadingTurnPromptArrowLabel
            : trailingTurnPromptArrowLabel
        hiddenArrowLabel.isHidden = true
        arrowLabel.attributedText = Styling.statusLabelAttributedString(configuration.text)
        arrowLabel.isHidden = false

        let offset = configuration.placesAfterText
            ? Styling.turnPromptArrowAnimationOffset
            : -Styling.turnPromptArrowAnimationOffset
        startTurnPromptArrowAnimation(on: arrowLabel, offset: offset)
    }

    private func startTurnPromptArrowAnimation(on label: UILabel, offset: CGFloat) {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = offset
        animation.duration = Styling.turnPromptArrowAnimationDuration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        label.layer.add(animation, forKey: turnPromptArrowAnimationKey)
    }

    private func stopTurnPromptArrowAnimation(on label: UILabel) {
        label.layer.removeAnimation(forKey: turnPromptArrowAnimationKey)
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
