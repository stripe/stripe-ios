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
        static let troubleLinkTopPadding: CGFloat = 12
        static let captureGuideShadowFadeInDuration: TimeInterval = 0.6
        static let livePreviewBlurFadeInDuration: TimeInterval = 0.3
        static let livePreviewBlurFadeOutDuration: TimeInterval = 0.6
        static var livePreviewBlurEffect: UIBlurEffect {
            UIBlurEffect(style: .regular)
        }
        static let statusLabelFadeInDuration: TimeInterval = 0.18
        static let statusLabelFadeOutDuration: TimeInterval = 0.6
        static let turnPromptArrowAnimationDuration: TimeInterval = 0.45
        static let turnPromptArrowAnimationOffset: CGFloat = 5
        static var troubleLinkFont: UIFont {
            IdentityUI.preferredFont(forTextStyle: .body).withSize(12)
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
                }
            }

            var turnPromptArrowText: String? {
                switch self {
                case .lookLeft:
                    return "←"
                case .lookRight:
                    return "→"
                case .placeFace,
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
        let havingTroubleHandler: (() -> Void)?

        init(
            state: State,
            instructionalText: String,
            havingTroubleHandler: (() -> Void)? = nil
        ) {
            self.state = state
            self.instructionalText = instructionalText
            self.havingTroubleHandler = havingTroubleHandler
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

    private lazy var havingTroubleLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = true
        label.accessibilityTraits = .link
        label.isUserInteractionEnabled = true
        label.isHidden = true
        label.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(didTapHavingTrouble)
        ))
        return label
    }()

    private let trailingTurnPromptArrowLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
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
        label.font = .systemFont(ofSize: 12, weight: .medium)
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
        label.font = .systemFont(ofSize: 12, weight: .medium)
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

    /// Called when the user taps on the "Having Trouble?" link
    private var havingTroubleHandler: (() -> Void)?

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
        havingTroubleHandler = viewModel.havingTroubleHandler

        let isCurrentlyShowingScanned = !scannedImageScrollView.isHidden

        // Reset values
        instructionLabelView.isHidden = false
        cameraPreviewView.isHidden = true
        capturedImageView.isHidden = true
        capturedImageView.image = nil
        captureTickMarksView.isHidden = true
        statusActivityIndicatorView.stopAnimating()
        previewContainerView.isHidden = true
        havingTroubleLabel.isHidden = true
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
            havingTroubleLabel.isHidden = viewModel.havingTroubleHandler == nil

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
            havingTroubleLabel.isHidden = viewModel.havingTroubleHandler == nil
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
            case .capturedFront,
                .capturedLeft,
                .capturedRight:
                return false
            case .placeFace,
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
            capturedImageBlurView.effect = isVisible ? Styling.livePreviewBlurEffect : nil
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
            capturedImageBlurView.effect = isVisible ? Styling.livePreviewBlurEffect : nil
            capturedImageBlurView.isHidden = !isVisible
            return
        }

        let animator = UIViewPropertyAnimator(duration: duration, curve: .easeInOut) {
            self.capturedImageBlurView.effect = isVisible ? Styling.livePreviewBlurEffect : nil
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
            self.configureHavingTroubleLabel()
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
        vStack.addArrangedSubview(havingTroubleLabel)
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
        vStack.setCustomSpacing(Styling.troubleLinkTopPadding, after: previewContainerView)
        configureHavingTroubleLabel()

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
            havingTroubleLabel.widthAnchor.constraint(
                lessThanOrEqualTo: widthAnchor,
                constant: -(Styling.contentInsets.leading + Styling.contentInsets.trailing)
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
        statusLabel.text = statusText.text
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
        arrowLabel.text = configuration.text
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

    fileprivate func configureHavingTroubleLabel() {
        havingTroubleLabel.attributedText = NSAttributedString(
            string: STPLocalizedString(
                "Having Trouble?",
                "Link text displayed under the selfie viewfinder"
            ),
            attributes: [
                .font: Styling.troubleLinkFont,
                .foregroundColor: IdentityUI.secondaryLabelColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ]
        )
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

    @objc fileprivate func didTapHavingTrouble() {
        havingTroubleHandler?()
    }
}

// MARK: - CheckboxButton
extension SelfieScanningView: CheckboxButtonDelegate {
    func checkboxButton(_ checkboxButton: CheckboxButton, shouldOpen url: URL) -> Bool {
        openURLHandler?(url)
        return false
    }
}

private final class CaptureTickMarksView: UIView {
    struct Styling {
        static let tickCount = 68
        static let tickLength: CGFloat = 10.25
        static let highlightedTickLength: CGFloat = 18.75
        static let tickWidth: CGFloat = 2.09
        static let highlightedTickWidth: CGFloat = 4.025
        static let baseTickFadeAnimationDuration: TimeInterval = 1.0
        static let baseTickOppositeSideMinOpacityMultiplier: CGFloat = 0.02
        static let baseTickOppositeSideFadeExponent: CGFloat = 0.25
        static let legacyHighlightAnimationDuration: TimeInterval = 0.18
        static let instructionAnimationDuration: TimeInterval = 0.72
        static let feedbackAnimationDuration: TimeInterval = 0.15
        static let successAnimationDuration: TimeInterval = 0.42
        static let successFadeOutDuration: TimeInterval = 0.34
        static let successCheckmarkSize: CGFloat = 28
        static let successCheckmarkInitialScale: CGFloat = 0.72
        static let horizontalDiameterToWidthRatio: CGFloat = 0.57
        static let verticalDiameterToHeightRatio: CGFloat = 0.57
        static let centerYRatio: CGFloat = 0.5
        static let tickColor = UIColor.white.withAlphaComponent(0.9)
        static let acceptedTickColor = UIColor(
            red: 0x31 / 255,
            green: 0xC9 / 255,
            blue: 0x5F / 255,
            alpha: 1
        )
        static let shadowColor = UIColor.black.withAlphaComponent(0.22)
        static let shadowOffset = CGSize(width: 0, height: 1)
        static let shadowBlur: CGFloat = 3.5
        static let centeredShadowOuterOpacity: CGFloat = 0.68
        static let centeredShadowClearPadding: CGFloat = 8
        static let centeredShadowGradientStepCount = 16
        static let centeredShadowFadeInDuration: TimeInterval = SelfieScanningView.Styling.captureGuideShadowFadeInDuration
    }

    private var uses3DCaptureAnimations = false
    private var captureGuideHighlight: SelfieScanningView.ViewModel.CaptureGuideHighlight = .none
    private var captureGuideTarget: SelfieScanningView.ViewModel.CaptureGuideTarget = .none
    private var targetProgress: CGFloat = 0
    private var displayedTargetProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var targetProgressAnimationStartValue: CGFloat = 0
    private var targetProgressAnimationStartTime: CFTimeInterval?
    private var baseTickFadeProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var baseTickFadeAnimationStartTime: CFTimeInterval?
    private var directionalPulseProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var directionalPulseAnimationStartTime: CFTimeInterval?
    private var highlightedTickProgress: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var highlightedTickOpacity: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var showsCenteredShadow: Bool = false
    private var centeredShadowOpacity: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    private var highlightedTickDisplayLink: CADisplayLink?
    private var highlightedTickAnimationStartTime: CFTimeInterval?
    private var targetTickDisplayLink: CADisplayLink?
    private var centeredShadowDisplayLink: CADisplayLink?
    private var centeredShadowAnimationStartTime: CFTimeInterval?

    private let successCheckmarkView: CaptureSuccessCheckmarkView = {
        let view = CaptureSuccessCheckmarkView()
        view.alpha = 0
        view.isHidden = true
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.28
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(successCheckmarkView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        highlightedTickDisplayLink?.invalidate()
        targetTickDisplayLink?.invalidate()
        centeredShadowDisplayLink?.invalidate()
    }

    func setUses3DCaptureAnimations(_ uses3DCaptureAnimations: Bool) {
        guard uses3DCaptureAnimations != self.uses3DCaptureAnimations else {
            return
        }

        self.uses3DCaptureAnimations = uses3DCaptureAnimations
        resetTargetAnimation()
        resetHighlightAnimation()
    }

    func setCaptureGuideTarget(
        _ captureGuideTarget: SelfieScanningView.ViewModel.CaptureGuideTarget,
        progress: CGFloat,
        animated: Bool
    ) {
        let clampedProgress = min(max(progress, 0), 1)
        let didChangeTarget = captureGuideTarget != self.captureGuideTarget
        guard didChangeTarget || clampedProgress != targetProgress else {
            return
        }

        self.captureGuideTarget = captureGuideTarget
        targetProgress = clampedProgress

        guard uses3DCaptureAnimations, captureGuideTarget != .none else {
            resetTargetAnimation()
            return
        }

        if didChangeTarget {
            displayedTargetProgress = 0
            baseTickFadeProgress = 0
            baseTickFadeAnimationStartTime = CACurrentMediaTime()
            directionalPulseProgress = 0
            directionalPulseAnimationStartTime = CACurrentMediaTime()
        }

        guard animated, window != nil else {
            displayedTargetProgress = clampedProgress
            baseTickFadeProgress = 1
            baseTickFadeAnimationStartTime = nil
            targetProgressAnimationStartTime = nil
            directionalPulseProgress = 0
            directionalPulseAnimationStartTime = nil
            return
        }

        targetProgressAnimationStartValue = displayedTargetProgress
        targetProgressAnimationStartTime = CACurrentMediaTime()
        startTargetTickDisplayLinkIfNeeded()
    }

    func setShowsCenteredShadow(_ showsCenteredShadow: Bool, animated: Bool) {
        guard showsCenteredShadow != self.showsCenteredShadow else {
            return
        }

        self.showsCenteredShadow = showsCenteredShadow
        centeredShadowDisplayLink?.invalidate()
        centeredShadowDisplayLink = nil
        centeredShadowAnimationStartTime = nil

        guard showsCenteredShadow else {
            centeredShadowOpacity = 0
            return
        }

        guard animated, window != nil else {
            centeredShadowOpacity = 1
            return
        }

        centeredShadowOpacity = 0
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateCenteredShadowFadeIn)
        )
        displayLink.add(to: .main, forMode: .common)
        centeredShadowDisplayLink = displayLink
    }

    func setCaptureGuideHighlight(
        _ captureGuideHighlight: SelfieScanningView.ViewModel.CaptureGuideHighlight,
        animated: Bool
    ) {
        guard captureGuideHighlight != self.captureGuideHighlight else {
            return
        }

        self.captureGuideHighlight = captureGuideHighlight
        highlightedTickDisplayLink?.invalidate()
        highlightedTickDisplayLink = nil
        highlightedTickAnimationStartTime = nil

        guard captureGuideHighlight != .none else {
            highlightedTickProgress = 0
            highlightedTickOpacity = 0
            successCheckmarkView.alpha = 0
            successCheckmarkView.isHidden = true
            return
        }

        guard animated, window != nil else {
            highlightedTickProgress = 1
            highlightedTickOpacity = 1
            configureSuccessCheckmark(progress: 1, opacity: 1)
            return
        }

        highlightedTickProgress = 0
        highlightedTickOpacity = 0
        successCheckmarkView.isHidden = !uses3DCaptureAnimations
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateHighlightedTickAnimation)
        )
        displayLink.add(to: .main, forMode: .common)
        highlightedTickDisplayLink = displayLink
    }

    @objc private func updateHighlightedTickAnimation(_ displayLink: CADisplayLink) {
        if highlightedTickAnimationStartTime == nil {
            highlightedTickAnimationStartTime = displayLink.timestamp
        }
        guard let highlightedTickAnimationStartTime else {
            return
        }

        let elapsedTime = displayLink.timestamp - highlightedTickAnimationStartTime
        if uses3DCaptureAnimations {
            let fadeInProgress = min(
                max(elapsedTime / Styling.successAnimationDuration, 0),
                1
            )
            highlightedTickProgress = materialEase(fadeInProgress)

            if elapsedTime <= Styling.successAnimationDuration {
                highlightedTickOpacity = highlightedTickProgress
            } else {
                let fadeOutProgress = min(
                    max(
                        (elapsedTime - Styling.successAnimationDuration)
                            / Styling.successFadeOutDuration,
                        0
                    ),
                    1
                )
                highlightedTickOpacity = 1 - fadeOutProgress
            }
            configureSuccessCheckmark(
                progress: highlightedTickProgress,
                opacity: highlightedTickOpacity
            )

            if elapsedTime >= Styling.successAnimationDuration + Styling.successFadeOutDuration {
                displayLink.invalidate()
                highlightedTickDisplayLink = nil
                self.highlightedTickAnimationStartTime = nil
                highlightedTickProgress = 1
                highlightedTickOpacity = 0
                successCheckmarkView.alpha = 0
                successCheckmarkView.isHidden = true
            }
            return
        }

        let progress = min(max(elapsedTime / Styling.legacyHighlightAnimationDuration, 0), 1)
        highlightedTickProgress = progress
        highlightedTickOpacity = 1 - pow(1 - progress, 2)
        if progress >= 1 {
            displayLink.invalidate()
            highlightedTickDisplayLink = nil
            self.highlightedTickAnimationStartTime = nil
            highlightedTickProgress = 1
            highlightedTickOpacity = 1
        }
    }

    @objc private func updateTargetTickAnimation(_ displayLink: CADisplayLink) {
        if let directionalPulseAnimationStartTime {
            let progress = min(
                max(
                    (displayLink.timestamp - directionalPulseAnimationStartTime)
                        / Styling.instructionAnimationDuration,
                    0
                ),
                1
            )
            if progress < 0.5 {
                directionalPulseProgress = materialEase(progress * 2)
            } else {
                directionalPulseProgress = 1 - materialEase((progress - 0.5) * 2)
            }
            if progress >= 1 {
                self.directionalPulseAnimationStartTime = nil
                directionalPulseProgress = 0
            }
        }

        if let targetProgressAnimationStartTime {
            let progress = min(
                max(
                    (displayLink.timestamp - targetProgressAnimationStartTime)
                        / Styling.feedbackAnimationDuration,
                    0
                ),
                1
            )
            let easedProgress = 1 - pow(1 - progress, 3)
            displayedTargetProgress = targetProgressAnimationStartValue
                + ((targetProgress - targetProgressAnimationStartValue) * easedProgress)
            if progress >= 1 {
                self.targetProgressAnimationStartTime = nil
                displayedTargetProgress = targetProgress
            }
        }
        if let baseTickFadeAnimationStartTime {
            let progress = min(
                max(
                    (displayLink.timestamp - baseTickFadeAnimationStartTime)
                        / Styling.baseTickFadeAnimationDuration,
                    0
                ),
                1
            )
            baseTickFadeProgress = materialEase(progress)
            if progress >= 1 {
                self.baseTickFadeAnimationStartTime = nil
                baseTickFadeProgress = 1
            }
        }

        if directionalPulseAnimationStartTime == nil
            && targetProgressAnimationStartTime == nil
            && baseTickFadeAnimationStartTime == nil
        {
            displayLink.invalidate()
            targetTickDisplayLink = nil
        }
    }

    private func startTargetTickDisplayLinkIfNeeded() {
        guard targetTickDisplayLink == nil,
            directionalPulseAnimationStartTime != nil
                || targetProgressAnimationStartTime != nil
                || baseTickFadeAnimationStartTime != nil
        else {
            return
        }

        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateTargetTickAnimation)
        )
        displayLink.add(to: .main, forMode: .common)
        targetTickDisplayLink = displayLink
    }

    private func resetTargetAnimation() {
        targetTickDisplayLink?.invalidate()
        targetTickDisplayLink = nil
        captureGuideTarget = .none
        targetProgress = 0
        displayedTargetProgress = 0
        baseTickFadeProgress = 0
        baseTickFadeAnimationStartTime = nil
        targetProgressAnimationStartTime = nil
        directionalPulseProgress = 0
        directionalPulseAnimationStartTime = nil
    }

    private func resetHighlightAnimation() {
        highlightedTickDisplayLink?.invalidate()
        highlightedTickDisplayLink = nil
        highlightedTickAnimationStartTime = nil
        captureGuideHighlight = .none
        highlightedTickProgress = 0
        highlightedTickOpacity = 0
        successCheckmarkView.alpha = 0
        successCheckmarkView.isHidden = true
    }

    private func configureSuccessCheckmark(progress: CGFloat, opacity: CGFloat) {
        guard uses3DCaptureAnimations else {
            successCheckmarkView.isHidden = true
            return
        }

        successCheckmarkView.isHidden = false
        successCheckmarkView.alpha = opacity
        let scale = Styling.successCheckmarkInitialScale
            + ((1 - Styling.successCheckmarkInitialScale) * progress)
        successCheckmarkView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }

    private func materialEase(_ progress: CGFloat) -> CGFloat {
        let clampedProgress = min(max(progress, 0), 1)
        var parameter = clampedProgress
        for _ in 0..<5 {
            let x = cubicBezier(parameter, controlPoint1: 0.4, controlPoint2: 0.2)
            let slope = cubicBezierSlope(parameter, controlPoint1: 0.4, controlPoint2: 0.2)
            guard abs(slope) > 0.0001 else {
                break
            }
            parameter = min(max(parameter - ((x - clampedProgress) / slope), 0), 1)
        }
        return cubicBezier(parameter, controlPoint1: 0, controlPoint2: 1)
    }

    private func cubicBezier(
        _ progress: CGFloat,
        controlPoint1: CGFloat,
        controlPoint2: CGFloat
    ) -> CGFloat {
        let inverseProgress = 1 - progress
        return (3 * inverseProgress * inverseProgress * progress * controlPoint1)
            + (3 * inverseProgress * progress * progress * controlPoint2)
            + (progress * progress * progress)
    }

    private func cubicBezierSlope(
        _ progress: CGFloat,
        controlPoint1: CGFloat,
        controlPoint2: CGFloat
    ) -> CGFloat {
        let inverseProgress = 1 - progress
        return (3 * inverseProgress * inverseProgress * controlPoint1)
            + (6 * inverseProgress * progress * (controlPoint2 - controlPoint1))
            + (3 * progress * progress * (1 - controlPoint2))
    }

    @objc private func updateCenteredShadowFadeIn(_ displayLink: CADisplayLink) {
        if centeredShadowAnimationStartTime == nil {
            centeredShadowAnimationStartTime = displayLink.timestamp
        }
        guard let centeredShadowAnimationStartTime else {
            return
        }

        let elapsedTime = displayLink.timestamp - centeredShadowAnimationStartTime
        let progress = min(
            max(elapsedTime / Styling.centeredShadowFadeInDuration, 0),
            1
        )
        centeredShadowOpacity = 1 - ((1 - progress) * (1 - progress))

        if progress >= 1 {
            displayLink.invalidate()
            centeredShadowDisplayLink = nil
            self.centeredShadowAnimationStartTime = nil
            centeredShadowOpacity = 1
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        successCheckmarkView.bounds = CGRect(
            origin: .zero,
            size: CGSize(
                width: Styling.successCheckmarkSize,
                height: Styling.successCheckmarkSize
            )
        )
        successCheckmarkView.center = CGPoint(
            x: bounds.midX,
            y: bounds.height * Styling.centerYRatio
        )
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        let horizontalRadius = bounds.width * Styling.horizontalDiameterToWidthRatio / 2
        let verticalRadius = bounds.height * Styling.verticalDiameterToHeightRatio / 2
        let center = CGPoint(
            x: bounds.midX,
            y: bounds.height * Styling.centerYRatio
        )

        if showsCenteredShadow, centeredShadowOpacity > 0 {
            drawCenteredShadow(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                opacity: centeredShadowOpacity
            )
        }

        drawBaseTicks(
            in: context,
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius
        )

        if uses3DCaptureAnimations,
            captureGuideTarget != .none,
            directionalPulseProgress > 0
        {
            let tickLength = Styling.tickLength
                + ((Styling.highlightedTickLength - Styling.tickLength)
                    * directionalPulseProgress)
            context.setLineWidth(Styling.tickWidth)
            context.setStrokeColor(Styling.tickColor.cgColor)
            drawTicks(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                tickLength: tickLength,
                growsOutward: true,
                outwardGrowthScale: { abs(cos($0)) },
                shouldDrawTick: { [weak self] angle in
                    self?.shouldDrawDirectionalPulseTick(at: angle) ?? false
                }
            )
            context.strokePath()
        }

        if uses3DCaptureAnimations,
            captureGuideTarget != .none,
            displayedTargetProgress > 0
        {
            drawAcceptedTicks(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                tickLength: Styling.highlightedTickLength,
                growsOutward: true,
                opacity: 1,
                shouldDrawTick: { [weak self] angle in
                    self?.isTickRevealedByProgress(at: angle) ?? false
                }
            )
        }

        if captureGuideHighlight != .none,
            highlightedTickProgress > 0,
            highlightedTickOpacity > 0
        {
            let highlightedTickLength = Styling.tickLength
                + ((Styling.highlightedTickLength - Styling.tickLength)
                    * highlightedTickProgress)
            drawAcceptedTicks(
                in: context,
                center: center,
                horizontalRadius: horizontalRadius,
                verticalRadius: verticalRadius,
                tickLength: highlightedTickLength,
                growsOutward: uses3DCaptureAnimations,
                opacity: highlightedTickOpacity,
                shouldDrawTick: { [weak self] angle in
                    self?.isTickHighlighted(at: angle) ?? false
                }
            )
        }
    }

    private func drawAcceptedTicks(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        tickLength: CGFloat,
        growsOutward: Bool,
        opacity: CGFloat,
        shouldDrawTick: (CGFloat) -> Bool
    ) {
        let clampedOpacity = min(max(opacity, 0), 1)

        context.saveGState()
        context.setLineCap(.round)
        context.setLineWidth(Styling.highlightedTickWidth)
        context.setShadow(offset: .zero, blur: 0, color: nil)
        context.setStrokeColor(
            Styling.acceptedTickColor.withAlphaComponent(clampedOpacity).cgColor
        )
        drawTicks(
            in: context,
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius,
            tickLength: tickLength,
            growsOutward: growsOutward,
            shouldDrawTick: shouldDrawTick
        )
        context.strokePath()
        context.restoreGState()
    }

    private func drawBaseTicks(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat
    ) {
        context.saveGState()
        context.setLineWidth(Styling.tickWidth)
        context.setLineCap(.round)
        context.setShadow(
            offset: Styling.shadowOffset,
            blur: Styling.shadowBlur,
            color: Styling.shadowColor.cgColor
        )

        forEachTick(
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius,
            tickLength: Styling.tickLength,
            shouldDrawTick: { [weak self] angle in
                self?.shouldDrawBaseTick(at: angle) ?? true
            }
        ) { angle, startPoint, endPoint in
            context.setStrokeColor(baseTickColor(at: angle).cgColor)
            context.move(to: startPoint)
            context.addLine(to: endPoint)
            context.strokePath()
        }
        context.restoreGState()
    }

    private func drawTicks(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        tickLength: CGFloat,
        growsOutward: Bool = false,
        outwardGrowthScale: ((CGFloat) -> CGFloat)? = nil,
        shouldDrawTick: (CGFloat) -> Bool
    ) {
        forEachTick(
            center: center,
            horizontalRadius: horizontalRadius,
            verticalRadius: verticalRadius,
            tickLength: tickLength,
            growsOutward: growsOutward,
            outwardGrowthScale: outwardGrowthScale,
            shouldDrawTick: shouldDrawTick
        ) { _, startPoint, endPoint in

            context.move(to: startPoint)
            context.addLine(to: endPoint)
        }
    }

    private func forEachTick(
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        tickLength: CGFloat,
        growsOutward: Bool = false,
        outwardGrowthScale: ((CGFloat) -> CGFloat)? = nil,
        shouldDrawTick: (CGFloat) -> Bool,
        _ body: (CGFloat, CGPoint, CGPoint) -> Void
    ) {
        for index in 0..<Styling.tickCount {
            let angle = (CGFloat(index) / CGFloat(Styling.tickCount)) * .pi * 2
            guard shouldDrawTick(angle) else {
                continue
            }

            let cosAngle = cos(angle)
            let sinAngle = sin(angle)
            let tickCenter = CGPoint(
                x: center.x + cosAngle * horizontalRadius,
                y: center.y + sinAngle * verticalRadius
            )
            let normal = CGVector(
                dx: cosAngle / horizontalRadius,
                dy: sinAngle / verticalRadius
            )
            let normalLength = sqrt((normal.dx * normal.dx) + (normal.dy * normal.dy))
            let unitNormal = CGVector(
                dx: normal.dx / normalLength,
                dy: normal.dy / normalLength
            )
            let growthScale = min(max(outwardGrowthScale?(angle) ?? 1, 0), 1)
            let scaledTickLength = Styling.tickLength
                + ((tickLength - Styling.tickLength) * growthScale)
            let innerTickLength = growsOutward ? Styling.tickLength / 2 : scaledTickLength / 2
            let outerTickLength = growsOutward
                ? scaledTickLength - innerTickLength
                : scaledTickLength / 2
            let startPoint = CGPoint(
                x: tickCenter.x - unitNormal.dx * innerTickLength,
                y: tickCenter.y - unitNormal.dy * innerTickLength
            )
            let endPoint = CGPoint(
                x: tickCenter.x + unitNormal.dx * outerTickLength,
                y: tickCenter.y + unitNormal.dy * outerTickLength
            )

            body(angle, startPoint, endPoint)
        }
    }

    private func isTickInTargetHalf(at angle: CGFloat) -> Bool {
        switch captureGuideTarget {
        case .none:
            return false
        case .left:
            return angle >= .pi * 0.5 && angle <= .pi * 1.5
        case .right:
            return angle <= .pi * 0.5 || angle >= .pi * 1.5
        }
    }

    private func isTickRevealedByProgress(at angle: CGFloat) -> Bool {
        guard isTickInTargetHalf(at: angle) else {
            return false
        }

        let centerAngle: CGFloat
        switch captureGuideTarget {
        case .none:
            return false
        case .left:
            centerAngle = .pi
        case .right:
            centerAngle = 0
        }

        let angularDistance = abs(atan2(sin(angle - centerAngle), cos(angle - centerAngle)))
        let hiddenAngle = (1 - displayedTargetProgress) * .pi * 0.5
        return angularDistance >= hiddenAngle && angularDistance <= .pi * 0.5
    }

    private func baseTickColor(at angle: CGFloat) -> UIColor {
        return Styling.tickColor.withAlphaComponent(
            Styling.tickColor.cgColor.alpha * baseTickOpacity(at: angle)
        )
    }

    private func baseTickOpacity(at angle: CGFloat) -> CGFloat {
        guard uses3DCaptureAnimations,
            let oppositeSideAngle = oppositeSideAngleForBaseFade()
        else {
            return 1
        }

        let oppositeSideAlignment = max(0, cos(angle - oppositeSideAngle))
        let oppositeSideFadeStrength = pow(
            oppositeSideAlignment,
            Styling.baseTickOppositeSideFadeExponent
        )
        let fadedOpacity = 1
            - ((1 - Styling.baseTickOppositeSideMinOpacityMultiplier) * oppositeSideFadeStrength)
        return baseTickFadeProgress * fadedOpacity
    }

    private func oppositeSideAngleForBaseFade() -> CGFloat? {
        switch captureGuideTarget {
        case .none:
            return nil
        case .left:
            return 0
        case .right:
            return .pi
        }
    }
    private func shouldDrawBaseTick(at angle: CGFloat) -> Bool {
        return !isTickCoveredByAcceptedState(at: angle)
    }

    private func shouldDrawDirectionalPulseTick(at angle: CGFloat) -> Bool {
        return isTickInTargetHalf(at: angle) && !isTickCoveredByAcceptedState(at: angle)
    }

    private func isTickCoveredByAcceptedState(at angle: CGFloat) -> Bool {
        let isAcceptedTargetTick = uses3DCaptureAnimations
            && captureGuideTarget != .none
            && displayedTargetProgress > 0
            && isTickRevealedByProgress(at: angle)
        let isAcceptedHighlightTick = captureGuideHighlight != .none
            && highlightedTickProgress > 0
            && highlightedTickOpacity > 0
            && isTickHighlighted(at: angle)
        return isAcceptedTargetTick || isAcceptedHighlightTick
    }

    private func isTickHighlighted(at angle: CGFloat) -> Bool {
        switch captureGuideHighlight {
        case .none:
            return false
        case .front:
            return true
        case .left:
            return angle > .pi * 0.5 && angle < .pi * 1.5
        case .right:
            return angle < .pi * 0.5 || angle > .pi * 1.5
        }
    }

    private func drawCenteredShadow(
        in context: CGContext,
        center: CGPoint,
        horizontalRadius: CGFloat,
        verticalRadius: CGFloat,
        opacity: CGFloat
    ) {
        let scaleX = horizontalRadius / verticalRadius
        let maxXDistance = max(center.x, bounds.width - center.x) / scaleX
        let maxYDistance = max(center.y, bounds.height - center.y)
        let outerRadius = hypot(maxXDistance, maxYDistance)
        let clearRadius = verticalRadius + Styling.centeredShadowClearPadding
        guard outerRadius > clearRadius else {
            return
        }

        let gradientSteps = max(Styling.centeredShadowGradientStepCount, 2)
        let denominator = CGFloat(gradientSteps - 1)
        let colors = (0..<gradientSteps).map { index -> CGColor in
            let progress = CGFloat(index) / denominator
            let smoothProgress = progress * progress * (3 - (2 * progress))
            let alpha = Styling.centeredShadowOuterOpacity * smoothProgress * opacity
            return UIColor.black.withAlphaComponent(alpha).cgColor
        } as CFArray
        let locations = (0..<gradientSteps).map { index in
            CGFloat(index) / denominator
        }

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        ) else {
            return
        }

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: scaleX, y: 1)
        context.drawRadialGradient(
            gradient,
            startCenter: .zero,
            startRadius: clearRadius,
            endCenter: .zero,
            endRadius: outerRadius,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }
}

private final class CaptureSuccessCheckmarkView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              bounds.width > 0,
              bounds.height > 0 else {
            return
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: bounds.insetBy(dx: 1, dy: 1))

        let checkmarkPath = UIBezierPath()
        checkmarkPath.move(to: CGPoint(x: bounds.width * 0.31, y: bounds.height * 0.52))
        checkmarkPath.addLine(to: CGPoint(x: bounds.width * 0.44, y: bounds.height * 0.65))
        checkmarkPath.addLine(to: CGPoint(x: bounds.width * 0.70, y: bounds.height * 0.38))
        checkmarkPath.lineCapStyle = .round
        checkmarkPath.lineJoinStyle = .round
        checkmarkPath.lineWidth = 2.6
        CaptureTickMarksView.Styling.acceptedTickColor.setStroke()
        checkmarkPath.stroke()
    }
}
