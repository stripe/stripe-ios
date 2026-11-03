//
//  AutomaticCardScanView.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)

import AVFoundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// A large camera viewfinder that starts scanning for a card as soon as it appears on screen.
/// Used by `AutomaticCardScanViewController`.
/// For internal SDK use only
@available(macCatalyst 14.0, *)
final class AutomaticCardScanView: UIView {

    enum State: Equatable {
        /// Waiting for the customer to respond to the camera permission prompt.
        case requestingPermission
        /// The camera is running and looking for a card.
        case scanning
        /// A card was scanned. The preview holds the frame the card was scanned from.
        case scanned
        /// The camera can't be used, e.g. because the customer denied camera access.
        case unavailable
    }

    /// How long the scanned state is shown before `onScan` is called.
    static let scannedStateDuration: TimeInterval = 0.8

    private(set) var state: State = .requestingPermission
    var onStateChange: ((State) -> Void)?
    /// Called once the scanned state has been shown for `scannedStateDuration`.
    var onScan: ((STPPaymentMethodCardParams) -> Void)?

    private static let cardSizeRatio: CGFloat = 2.125 / 3.370  // ID-1 card size (in inches)
    private static let cardCornerRadius: CGFloat = 0.125 / 3.370  // radius / ID-1 card width
    private static let cardInset: CGFloat = 32
    private static let cardMinimumVerticalInset: CGFloat = 56
    private static let controlInset: CGFloat = 12
    private static let scannedColor: UIColor = .systemGreen

    private let appearance: PaymentSheet.Appearance
    /// Known once the camera starts
    private var isTorchAvailable = false
    private lazy var cardScanner = STPCardScanner(delegate: self)
    private var pendingScanCompletion: DispatchWorkItem?
    private var isTorchEnabled = false {
        didSet {
            updateTorchButton()
        }
    }
    private var sessionDidStartRunningObserver: NSObjectProtocol?

    // MARK: - Views

    private(set) lazy var cameraView: STPCameraView = {
        let cameraView = STPCameraView(frame: .zero)
        // The first few frames of the camera view will be black, so our background should be black too.
        cameraView.backgroundColor = .black
        cameraView.isAccessibilityElement = true
        cameraView.accessibilityLabel = STPLocalizedString(
            "Point the camera at your card.", "Accessibility instructions for card scanning.")
        return cameraView
    }()

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let blurMaskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillRule = .evenOdd
        return layer
    }()

    private let cardFrameView = makeCardFrameView(color: .white)
    private let scannedCardFrameView = makeCardFrameView(color: scannedColor)

    private let scannedCheckmarkView: UIView = {
        let circle = UIView()
        circle.backgroundColor = scannedColor
        circle.layer.cornerRadius = 24
        let checkmark = UIImageView(
            image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .bold))
        )
        checkmark.tintColor = .white
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        circle.addSubview(checkmark)
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: 48),
            circle.heightAnchor.constraint(equalToConstant: 48),
            checkmark.centerXAnchor.constraint(equalTo: circle.centerXAnchor),
            checkmark.centerYAnchor.constraint(equalTo: circle.centerYAnchor),
        ])
        return circle
    }()

    private lazy var statusIconView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(systemName: "checkmark.circle.fill", withConfiguration: UIImage.SymbolConfiguration(font: statusLabel.font))
        )
        imageView.tintColor = Self.scannedColor
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.asElementsTheme.fonts.footnoteEmphasis
        label.textColor = .white
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var statusPill: UIView = {
        let stackView = UIStackView(arrangedSubviews: [statusIconView, statusLabel])
        stackView.spacing = 6
        stackView.alignment = .center
        let pill = CapsuleView()
        pill.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        pill.accessibilityElements = [statusLabel]
        pill.addAndPinSubview(stackView, insets: .insets(top: 6, leading: 12, bottom: 6, trailing: 12))
        return pill
    }()

    private lazy var torchButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 18
        button.accessibilityLabel = STPLocalizedString(
            "Flashlight",
            "Accessibility label for a button that turns the flashlight on or off while scanning a card."
        )
        button.addTarget(self, action: #selector(didTapTorchButton), for: .touchUpInside)
        return button
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = String.Localized.allow_camera_access
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = appearance.asElementsTheme.fonts.subheadline
        label.textColor = .white
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    // MARK: - Initializers

    init(appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        super.init(frame: .zero)
        backgroundColor = .black
        clipsToBounds = true
        applyCornerRadiusOrConfiguration(for: appearance)
        cardScanner.cameraView = cameraView
        blurView.layer.mask = blurMaskLayer

        installConstraints()
        updateTorchButton()
        applyState()
        applyStatusPillContent()

        sessionDidStartRunningObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionDidStartRunning,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.cameraDidStartRunning()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        pendingScanCompletion?.cancel()
        if let sessionDidStartRunningObserver {
            NotificationCenter.default.removeObserver(sessionDidStartRunningObserver)
        }
    }

    private func installConstraints() {
        for view in [cameraView, blurView, cardFrameView, scannedCardFrameView, scannedCheckmarkView, statusPill, torchButton, messageLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        // Fill the width, but shrink to fit when the viewfinder is short (e.g. in landscape).
        let preferredCardWidth = cardFrameView.widthAnchor.constraint(equalTo: widthAnchor, constant: -Self.cardInset * 2)
        preferredCardWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: topAnchor),
            cameraView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cameraView.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            preferredCardWidth,
            cardFrameView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -Self.cardInset * 2),
            cardFrameView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, constant: -Self.cardMinimumVerticalInset * 2),
            cardFrameView.heightAnchor.constraint(equalTo: cardFrameView.widthAnchor, multiplier: Self.cardSizeRatio),
            cardFrameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardFrameView.centerYAnchor.constraint(equalTo: centerYAnchor),

            scannedCardFrameView.topAnchor.constraint(equalTo: cardFrameView.topAnchor),
            scannedCardFrameView.leadingAnchor.constraint(equalTo: cardFrameView.leadingAnchor),
            scannedCardFrameView.trailingAnchor.constraint(equalTo: cardFrameView.trailingAnchor),
            scannedCardFrameView.bottomAnchor.constraint(equalTo: cardFrameView.bottomAnchor),

            scannedCheckmarkView.centerXAnchor.constraint(equalTo: cardFrameView.centerXAnchor),
            scannedCheckmarkView.centerYAnchor.constraint(equalTo: cardFrameView.centerYAnchor),

            statusPill.centerXAnchor.constraint(equalTo: centerXAnchor),
            statusPill.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            statusPill.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),

            torchButton.topAnchor.constraint(equalTo: topAnchor, constant: Self.controlInset),
            torchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.controlInset),
            torchButton.widthAnchor.constraint(equalToConstant: 36),
            torchButton.heightAnchor.constraint(equalToConstant: 36),

            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.cardInset),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.cardInset),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let cardCornerRadius = cardFrameView.bounds.width * Self.cardCornerRadius
        cardFrameView.layer.cornerRadius = cardCornerRadius
        scannedCardFrameView.layer.cornerRadius = cardCornerRadius

        // Blur everything except the card cutout
        let path = UIBezierPath(rect: blurView.bounds)
        path.append(UIBezierPath(roundedRect: cardFrameView.frame, cornerRadius: cardCornerRadius))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        blurMaskLayer.frame = blurView.bounds
        blurMaskLayer.path = path.cgPath
        CATransaction.commit()
    }

    // MARK: - Scanning

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            beginScanningIfNeeded()
        } else {
            stopScanning()
        }
    }

    private func beginScanningIfNeeded() {
        guard state != .scanned else { return }
        #if targetEnvironment(simulator)
        // There's no camera on the simulator; the scanner reports an error as soon as it starts.
        startCamera()
        #else
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startCamera()
        case .notDetermined:
            setState(.requestingPermission, animated: false)
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                DispatchQueue.main.async {
                    guard let self, self.window != nil, self.state == .requestingPermission else { return }
                    if isGranted {
                        self.startCamera()
                    } else {
                        self.setState(.unavailable, animated: true)
                    }
                }
            }
        default:
            setState(.unavailable, animated: false)
        }
        #endif
    }

    private func startCamera() {
        // Fade the preview in once frames start arriving, rather than popping in over the black background
        cameraView.alpha = 0
        setState(.scanning, animated: state != .scanning)
        cardScanner.start()
    }

    private func cameraDidStartRunning() {
        guard state == .scanning, cameraView.alpha == 0 else { return }
        isTorchAvailable = cardScanner.isTorchAvailable
        UIView.animate(withDuration: 0.2, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.cameraView.alpha = 1
            self.applyState()
        }
    }

    /// Stops the camera. A scan that's being shown in the scanned state is discarded.
    func stopScanning() {
        pendingScanCompletion?.cancel()
        pendingScanCompletion = nil
        cardScanner.stop()
        isTorchEnabled = false
    }

    @objc private func didTapTorchButton() {
        isTorchEnabled.toggle()
        cardScanner.setTorchEnabled(isTorchEnabled)
    }

    // MARK: - State

    func setState(_ newState: State, animated: Bool) {
        guard newState != state else { return }
        state = newState
        if newState != .scanning {
            isTorchEnabled = false
        }

        if animated {
            animateStatusPill()
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: {
                    self.applyState()
                    self.layoutIfNeeded()
                }
            )
            if newState == .scanned {
                // Pop the checkmark in with a little bounce
                scannedCheckmarkView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                UIView.animate(
                    withDuration: 0.5,
                    delay: 0,
                    usingSpringWithDamping: 0.6,
                    initialSpringVelocity: 0,
                    options: [.allowUserInteraction],
                    animations: {
                        self.scannedCheckmarkView.transform = .identity
                    }
                )
            }
        } else {
            applyState()
            applyStatusPillContent()
        }

        if newState == .scanned {
            UIAccessibility.post(notification: .announcement, argument: statusLabel.text)
        }
        onStateChange?(newState)
    }

    /// Updates every view's visibility to match `state`.
    private func applyState() {
        let isCameraActive = state == .scanning || state == .scanned
        blurView.alpha = isCameraActive ? 1 : 0
        cardFrameView.alpha = state == .scanning ? 1 : 0
        scannedCardFrameView.alpha = state == .scanned ? 1 : 0
        scannedCheckmarkView.alpha = state == .scanned ? 1 : 0
        statusPill.alpha = isCameraActive ? 1 : 0
        torchButton.alpha = state == .scanning && isTorchAvailable ? 1 : 0
        messageLabel.alpha = state == .unavailable ? 1 : 0
        cameraView.accessibilityElementsHidden = !isCameraActive
        messageLabel.accessibilityElementsHidden = state != .unavailable
    }

    private func applyStatusPillContent() {
        statusIconView.setHiddenIfNecessary(state != .scanned)
        statusLabel.text = state == .scanned ? Self.scannedText : Self.scanningText
    }

    /// Fades the old status out, then resizes the pill and fades the new status in.
    private func animateStatusPill() {
        let contentViews = [statusLabel, statusIconView]
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseIn, .beginFromCurrentState]) {
            contentViews.forEach { $0.alpha = 0 }
        } completion: { _ in
            self.applyStatusPillContent()
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: {
                    contentViews.forEach { $0.alpha = 1 }
                    self.statusPill.layoutIfNeeded()
                    self.layoutIfNeeded()
                }
            )
        }
    }

    private func updateTorchButton() {
        let image = UIImage(systemName: "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold))
        torchButton.setImage(image, for: .normal)
        torchButton.tintColor = isTorchEnabled ? .black : .white
        torchButton.backgroundColor = isTorchEnabled ? .white : UIColor.black.withAlphaComponent(0.6)
        torchButton.isSelected = isTorchEnabled
    }

    // MARK: - Helpers

    private static var scanningText: String {
        STPLocalizedString(
            "Looking for your card",
            "Status shown over the camera while it looks for a payment card to scan."
        )
    }

    private static var scannedText: String {
        STPLocalizedString(
            "Card scanned",
            "Status shown over the camera after a payment card was scanned successfully."
        )
    }

    private static func makeCardFrameView(color: UIColor) -> UIView {
        let view = UIView()
        view.layer.borderWidth = 3
        view.layer.borderColor = color.cgColor
        view.isUserInteractionEnabled = false
        return view
    }
}

// MARK: - STPCardScannerDelegate

@available(macCatalyst 14.0, *)
extension AutomaticCardScanView: STPCardScannerDelegate {
    func cardScanner(_ scanner: STPCardScanner, didCompleteWith cardParams: STPPaymentMethodCardParams) {
        guard state == .scanning else { return }
        setState(.scanned, animated: true)
        let completion = DispatchWorkItem { [weak self] in
            self?.pendingScanCompletion = nil
            self?.onScan?(cardParams)
        }
        pendingScanCompletion = completion
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.scannedStateDuration, execute: completion)
    }

    func cardScannerDidError(_ scanner: STPCardScanner) {
        setState(.unavailable, animated: true)
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
