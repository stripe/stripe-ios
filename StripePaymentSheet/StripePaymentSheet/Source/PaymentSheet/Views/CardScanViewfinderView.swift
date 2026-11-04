//
//  CardScanViewfinderView.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

@available(macCatalyst 14.0, *)
protocol CardScanViewfinderViewDelegate: AnyObject {
    func cardScanViewfinderView(_ viewfinderView: CardScanViewfinderView, didScan cardParams: STPPaymentMethodCardParams)
    func cardScanViewfinderViewDidError(_ viewfinderView: CardScanViewfinderView)
}

/// A large camera viewfinder used by `CardScanViewController`.
/// It shows a card-shaped cutout, a torch toggle, and a status pill that reflects scanning progress.
/// For internal SDK use only
@available(macCatalyst 14.0, *)
final class CardScanViewfinderView: UIView {

    enum State: Equatable {
        case scanning
        case scanned
        case error
    }

    weak var delegate: CardScanViewfinderViewDelegate?

    var state: State = .scanning {
        didSet {
            updateForState()
        }
    }

    var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation {
        didSet {
            cardScanner.deviceOrientation = deviceOrientation
        }
    }

    private let theme: ElementsAppearance
    private lazy var cardScanner: STPCardScanner = {
        let cardScanner = STPCardScanner(delegate: self)
        cardScanner.cameraView = cameraView
        cardScanner.keepsLastFrameAfterSuccess = true
        return cardScanner
    }()

    private static let cardSizeRatio: CGFloat = 2.125 / 3.370  // ID-1 card size (in inches)
    private static let cardCornerRadius: CGFloat = 0.125 / 3.370  // radius / ID-1 card width
    private static let defaultCornerRadius: CGFloat = 12
    private static let cardHorizontalInset: CGFloat = 24
    private static let cardVerticalInset: CGFloat = 72
    private static let controlInset: CGFloat = 12
    private static let torchButtonSize: CGFloat = 40
    private static let outlineWidth: CGFloat = 3
    private static let successColor = UIColor.systemGreen

    private let isTorchAvailable = STPCardScanner.isTorchAvailable
    private var isTorchEnabled = false {
        didSet {
            updateTorchButton()
        }
    }

    // MARK: - Views

    private lazy var cameraView: STPCameraView = {
        let cameraView = STPCameraView(frame: .zero)
        cameraView.isAccessibilityElement = true
        cameraView.accessibilityLabel = STPLocalizedString(
            "Point the camera at your card.", "Accessibility instructions for card scanning.")
        // The first few frames of the camera view will be black, so our background should be black too.
        cameraView.backgroundColor = .black
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        return cameraView
    }()

    private lazy var outerBlurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var cardOutlineView: UIView = {
        let view = UIView()
        view.layer.borderWidth = Self.outlineWidth
        view.layer.borderColor = UIColor.white.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var successImageView: UIImageView = {
        let imageView = UIImageView(image: Self.makeSuccessImage(configuration: UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.alpha = 0
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.text = String.Localized.allow_camera_access
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = theme.fonts.subheadline
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var torchButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = Self.torchButtonSize / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapTorchButton), for: .touchUpInside)
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = theme.fonts.subheadline
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statusPillView: UIView = {
        let pill = CapsuleView()
        pill.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        pill.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: pill.topAnchor, constant: 8),
            statusLabel.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -8),
            statusLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -16),
        ])
        pill.isAccessibilityElement = true
        pill.accessibilityTraits = .updatesFrequently
        pill.translatesAutoresizingMaskIntoConstraints = false
        return pill
    }()

    // MARK: - Init

    init(theme: ElementsAppearance) {
        self.theme = theme
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = .black

        [cameraView, outerBlurView, cardOutlineView, successImageView, errorLabel, torchButton, statusPillView].forEach {
            addSubview($0)
        }

        if theme.cornerRadius == nil && LiquidGlassDetector.isEnabledInMerchantApp {
            ios26_applyDefaultCornerConfiguration()
        } else {
            layer.cornerRadius = theme.cornerRadius ?? Self.defaultCornerRadius
        }

        // Fill the available width, but shrink if the viewfinder is too short to fit the card at full width.
        let preferredCardWidth = cardOutlineView.widthAnchor.constraint(equalTo: widthAnchor, constant: -Self.cardHorizontalInset * 2)
        preferredCardWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: bottomAnchor),

            outerBlurView.topAnchor.constraint(equalTo: topAnchor),
            outerBlurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerBlurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerBlurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            cardOutlineView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardOutlineView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardOutlineView.heightAnchor.constraint(equalTo: cardOutlineView.widthAnchor, multiplier: Self.cardSizeRatio),
            cardOutlineView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -Self.cardHorizontalInset * 2),
            cardOutlineView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -Self.cardVerticalInset * 2),
            preferredCardWidth,

            successImageView.centerXAnchor.constraint(equalTo: cardOutlineView.centerXAnchor),
            successImageView.centerYAnchor.constraint(equalTo: cardOutlineView.centerYAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: cardOutlineView.leadingAnchor, constant: 8),
            errorLabel.trailingAnchor.constraint(equalTo: cardOutlineView.trailingAnchor, constant: -8),
            errorLabel.centerYAnchor.constraint(equalTo: cardOutlineView.centerYAnchor),

            torchButton.topAnchor.constraint(equalTo: topAnchor, constant: Self.controlInset),
            torchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.controlInset),
            torchButton.widthAnchor.constraint(equalToConstant: Self.torchButtonSize),
            torchButton.heightAnchor.constraint(equalToConstant: Self.torchButtonSize),

            statusPillView.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusPillView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.controlInset * 2),
            statusPillView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Self.controlInset),
            statusPillView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Self.controlInset),
        ])

        updateTorchButton()
        updateForState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scanning

    func startScanner() {
        state = .scanning
        isTorchEnabled = false
        cardScanner.start()
    }

    func stopScanner() {
        isTorchEnabled = false
        cardScanner.stop()
    }

    @objc private func didTapTorchButton() {
        isTorchEnabled.toggle()
        cardScanner.setTorchEnabled(isTorchEnabled)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let cardCornerRadius = cardOutlineView.bounds.width * Self.cardCornerRadius
        cardOutlineView.layer.cornerRadius = cardCornerRadius

        // Cut a card-shaped hole in the blur so the card is in focus and everything around it is dimmed.
        let outerPath = UIBezierPath(rect: bounds)
        outerPath.append(UIBezierPath(roundedRect: cardOutlineView.frame, cornerRadius: cardCornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = .evenOdd
        outerBlurView.layer.mask = maskLayer
    }

    // MARK: - State

    private func updateForState() {
        let isScanned = state == .scanned
        let isError = state == .error
        cardOutlineView.layer.borderColor = (isScanned ? Self.successColor : UIColor.white).cgColor
        successImageView.alpha = isScanned ? 1 : 0
        errorLabel.isHidden = !isError
        statusPillView.isHidden = isError
        torchButton.isHidden = isScanned || isError || !isTorchAvailable
        let statusText = isScanned ? String.Localized.card_scanned : String.Localized.looking_for_your_card
        if isScanned {
            // Lead the status with a checkmark, sized to match the text
            let attachment = NSTextAttachment()
            attachment.image = Self.makeSuccessImage(configuration: UIImage.SymbolConfiguration(font: statusLabel.font))
            let attributedText = NSMutableAttributedString(attachment: attachment)
            attributedText.append(NSAttributedString(string: " " + statusText))
            statusLabel.attributedText = attributedText
        } else {
            statusLabel.text = statusText
        }
        statusPillView.accessibilityLabel = statusText
    }

    /// A green circle with a white checkmark.
    private static func makeSuccessImage(configuration: UIImage.SymbolConfiguration) -> UIImage? {
        let paletteConfiguration = configuration.applying(UIImage.SymbolConfiguration(paletteColors: [.white, successColor]))
        return UIImage(systemName: "checkmark.circle.fill", withConfiguration: paletteConfiguration)
    }

    private func updateTorchButton() {
        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        let imageName = isTorchEnabled ? "bolt.slash.fill" : "bolt.fill"
        torchButton.setImage(UIImage(systemName: imageName, withConfiguration: configuration), for: .normal)
        torchButton.accessibilityLabel = isTorchEnabled
            ? STPLocalizedString("Turn off flashlight", "Accessibility label for a button that turns off the flashlight while scanning a card.")
            : STPLocalizedString("Turn on flashlight", "Accessibility label for a button that turns on the flashlight while scanning a card.")
    }
}

// MARK: - STPCardScannerDelegate

@available(macCatalyst 14.0, *)
extension CardScanViewfinderView: STPCardScannerDelegate {
    func cardScanner(_ scanner: STPCardScanner, didCompleteWith cardParams: STPPaymentMethodCardParams) {
        isTorchEnabled = false
        UIView.transition(with: self, duration: PaymentSheetUI.defaultAnimationDuration, options: .transitionCrossDissolve) {
            self.state = .scanned
        }
        UIAccessibility.post(notification: .announcement, argument: String.Localized.card_scanned)
        delegate?.cardScanViewfinderView(self, didScan: cardParams)
    }

    func cardScannerDidError(_ scanner: STPCardScanner) {
        isTorchEnabled = false
        state = .error
        delegate?.cardScanViewfinderViewDidError(self)
    }
}

// MARK: - CapsuleView

/// A view whose corners are always fully rounded.
private final class CapsuleView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
}

#endif
