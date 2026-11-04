//
//  AutomaticCardScanViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

@available(macCatalyst 14.0, *)
protocol AutomaticCardScanViewControllerDelegate: AnyObject {
    func automaticCardScanViewController(_ viewController: AutomaticCardScanViewController, didScan cardParams: STPPaymentMethodCardParams)
}

/// Shows the form header, scanning instructions, and a large card scanner, without the rest of the card form.
/// `PaymentSheetVerticalViewController` shows this in place of the card form when `opensCardScannerAutomatically` is enabled.
/// For internal SDK use only
@available(macCatalyst 14.0, *)
final class AutomaticCardScanViewController: UIViewController {

    /// The viewfinder's preferred height relative to its width.
    private static let scanViewAspectRatio: CGFloat = 1.35
    /// Keeps the viewfinder from pushing the sheet past the screen on short devices or in landscape.
    private static let maximumScanViewHeightRatio: CGFloat = 0.55

    weak var delegate: AutomaticCardScanViewControllerDelegate?

    let scanView: AutomaticCardScanView
    private let headerView: UIView
    private let appearance: PaymentSheet.Appearance
    private var maximumScanViewHeightConstraint: NSLayoutConstraint?

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = appearance.asElementsTheme.fonts.subheadline
        label.textColor = appearance.colors.textSecondary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    init(headerView: UIView, appearance: PaymentSheet.Appearance, delegate: AutomaticCardScanViewControllerDelegate) {
        self.headerView = headerView
        self.appearance = appearance
        self.delegate = delegate
        self.scanView = AutomaticCardScanView(appearance: appearance)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [headerView, subtitleLabel, scanView])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.setCustomSpacing(4, after: headerView)
        view.addAndPinSubview(stackView)

        let preferredHeight = scanView.heightAnchor.constraint(equalTo: scanView.widthAnchor, multiplier: Self.scanViewAspectRatio)
        preferredHeight.priority = .defaultHigh
        // Start from the screen height so the sheet's first measurement, made before this view is in a window, is already final
        let maximumHeight = scanView.heightAnchor.constraint(
            lessThanOrEqualToConstant: UIScreen.main.bounds.height * Self.maximumScanViewHeightRatio
        )
        maximumScanViewHeightConstraint = maximumHeight
        NSLayoutConstraint.activate([preferredHeight, maximumHeight])

        scanView.onStateChange = { [weak self] _ in
            self?.updateSubtitle(animated: true)
        }
        scanView.onScan = { [weak self] cardParams in
            guard let self else { return }
            self.delegate?.automaticCardScanViewController(self, didScan: cardParams)
        }
        updateSubtitle(animated: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let windowHeight = view.window?.bounds.height {
            maximumScanViewHeightConstraint?.constant = windowHeight * Self.maximumScanViewHeightRatio
        }
    }

    func stopScanning() {
        scanView.stopScanning()
    }

    private func updateSubtitle(animated: Bool) {
        let text: String = {
            switch scanView.state {
            case .requestingPermission, .unavailable:
                return STPLocalizedString(
                    "Allow camera permissions and get your card ready for scanning.",
                    "Instructions shown above the card scanner while the customer is asked for camera access."
                )
            case .scanning, .scanned:
                return STPLocalizedString(
                    "Hold your card with the number visible in the frame to scan it automatically.",
                    "Instructions shown above the card scanner while it looks for a payment card."
                )
            }
        }()
        guard subtitleLabel.text != text else { return }
        guard animated else {
            subtitleLabel.text = text
            return
        }
        UIView.transition(with: subtitleLabel, duration: 0.2, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.subtitleLabel.text = text
        }
        // The new instructions may wrap differently
        animateHeightChange()
    }
}

// MARK: - Buttons

@available(macCatalyst 14.0, *)
extension AutomaticCardScanViewController {

    /// A pill-shaped "Scan card" button shown in the form header, which reopens the scanner.
    final class HeaderScanButton: UIButton {
        /// After a scan, the button reads "Rescan card".
        var hasScannedCard: Bool = false {
            didSet {
                configuration?.title = hasScannedCard ? Self.rescanCardTitle : String.Localized.scan_card
            }
        }

        private static var rescanCardTitle: String {
            STPLocalizedString(
                "Rescan card",
                "Title for a button that opens the camera to scan a payment card again, after one was already scanned."
            )
        }

        init(appearance: PaymentSheet.Appearance) {
            super.init(frame: .zero)
            let theme = appearance.asElementsTheme
            let font = theme.fonts.footnoteEmphasis
            let iconConfiguration = UIImage.SymbolConfiguration(font: font, scale: .small)

            var configuration = UIButton.Configuration.filled()
            configuration.title = String.Localized.scan_card
            configuration.image = UIImage(
                systemName: appearance.iconStyle == .outlined ? "camera" : "camera.fill",
                withConfiguration: iconConfiguration
            )
            configuration.imagePadding = 4
            configuration.cornerStyle = .capsule
            configuration.contentInsets = .init(top: 4, leading: 10, bottom: 4, trailing: 10)
            configuration.baseForegroundColor = appearance.colors.primary
            configuration.baseBackgroundColor = appearance.colors.primary.withAlphaComponent(0.1)
            configuration.titleTextAttributesTransformer = .init { container in
                var container = container
                container.font = font
                return container
            }
            self.configuration = configuration
            setContentHuggingPriority(.required, for: .horizontal)
            setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    /// An outlined "Enter card details manually" button, shown in place of the primary button while scanning.
    final class ManualEntryButton: UIButton {
        private let appearance: PaymentSheet.Appearance

        init(appearance: PaymentSheet.Appearance) {
            self.appearance = appearance
            super.init(frame: .zero)
            var configuration = UIButton.Configuration.plain()
            configuration.title = String.Localized.enter_card_details_manually
            configuration.baseForegroundColor = appearance.colors.primary
            configuration.titleLineBreakMode = .byTruncatingTail
            let font = appearance.primaryButton.font ?? appearance.scaledFont(
                for: appearance.font.base.medium,
                style: .callout,
                maximumPointSize: 25
            )
            configuration.titleTextAttributesTransformer = .init { container in
                var container = container
                container.font = font
                return container
            }
            self.configuration = configuration
            backgroundColor = appearance.colors.componentBackground
            layer.borderWidth = appearance.borderWidth
            layer.borderColor = appearance.colors.componentBorder.cgColor
            applyCornerRadiusOrConfiguration(for: appearance, ios26DefaultCornerStyle: .capsule, shouldUsePrimaryButtonCornerRadius: true)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            layer.borderColor = appearance.colors.componentBorder.cgColor
        }
    }
}

#endif
