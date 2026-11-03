//
//  CardScanViewController.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)

import AVFoundation
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

@available(macCatalyst 14.0, *)
protocol CardScanViewControllerDelegate: AnyObject {
    /// Called after a successful scan, as soon as the screen starts popping back to the form.
    func cardScanViewController(_ viewController: CardScanViewController, didScan cardParams: STPPaymentMethodCardParams)
    /// Called when the customer chooses to type their card details instead, as soon as the screen starts popping back to the form.
    func cardScanViewControllerDidSelectManualEntry(_ viewController: CardScanViewController)
}

/// A full-height sheet screen that leads with the card scanner.
/// It is pushed on top of the card form when `opensCardScannerAutomatically` is enabled, and pops back to the form when the scan completes or the customer chooses to enter their card manually.
/// For internal SDK use only
@available(macCatalyst 14.0, *)
final class CardScanViewController: UIViewController {

    weak var delegate: CardScanViewControllerDelegate?

    /// The sheet content underneath this screen. Closing this screen closes the sheet through it.
    private weak var underlyingContentViewController: BottomSheetContentViewController?
    private let appearance: PaymentSheet.Appearance
    private let theme: ElementsAppearance

    /// How long the success state is shown before returning to the form.
    private static let successDisplayDuration: TimeInterval = 1.0
    private static let viewfinderAspectRatio: CGFloat = 1.25
    /// The viewfinder never takes more than this fraction of the window's height, so the screen fits on smaller devices.
    private static let maximumViewfinderHeightRatio: CGFloat = 0.5

    private var hasFinished = false

    // MARK: - Views

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = SheetNavigationBar(appearance: appearance)
        // Match the screen underneath, so customers can go back to wherever they came from (e.g. the payment method list).
        if case .back = underlyingContentViewController?.navigationBar.currentStyle {
            navigationBar.setStyle(.back(showAdditionalButton: false))
        } else {
            navigationBar.setStyle(.close(showAdditionalButton: false))
        }
        navigationBar.delegate = self
        return navigationBar
    }()

    private lazy var titleLabel: UILabel = {
        PaymentSheetUI.makeHeaderLabel(title: String.Localized.add_card, appearance: appearance)
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = appearance.colors.textSecondary
        label.numberOfLines = 0
        return label
    }()

    private(set) lazy var viewfinderView: CardScanViewfinderView = {
        let view = CardScanViewfinderView(theme: theme)
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var manualEntryButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = String.Localized.enter_card_details_manually
        configuration.baseForegroundColor = theme.colors.primary
        configuration.contentInsets = .init(top: 14, leading: 16, bottom: 14, trailing: 16)
        configuration.titleTextAttributesTransformer = .init { [appearance] container in
            var container = container
            container.font = appearance.scaledFont(for: appearance.font.base.medium, style: .callout, maximumPointSize: 25)
            return container
        }
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = appearance.colors.componentBackground
        background.strokeColor = appearance.colors.componentBorder
        background.strokeWidth = max(appearance.borderWidth, 1)
        background.cornerRadius = appearance.cornerRadius ?? ElementsUI.defaultCornerRadius
        configuration.background = background

        let button = UIButton(configuration: configuration)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(didTapManualEntry), for: .touchUpInside)
        return button
    }()

    private lazy var maximumViewfinderHeightConstraint: NSLayoutConstraint = {
        viewfinderView.heightAnchor.constraint(lessThanOrEqualToConstant: .greatestFiniteMagnitude)
    }()

    // MARK: - Init

    init(
        appearance: PaymentSheet.Appearance,
        theme: ElementsAppearance,
        underlyingContentViewController: BottomSheetContentViewController?
    ) {
        self.appearance = appearance
        self.theme = theme
        self.underlyingContentViewController = underlyingContentViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = appearance.colors.background

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 8

        let stackView = UIStackView(arrangedSubviews: [headerStack, viewfinderView, manualEntryButton])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.setCustomSpacing(16, after: headerStack)
        stackView.setCustomSpacing(40, after: viewfinderView)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = appearance.formInsets
        view.addAndPinSubview(stackView)

        let preferredViewfinderHeight = viewfinderView.heightAnchor.constraint(
            equalTo: viewfinderView.widthAnchor,
            multiplier: Self.viewfinderAspectRatio
        )
        preferredViewfinderHeight.priority = .defaultHigh
        NSLayoutConstraint.activate([preferredViewfinderHeight, maximumViewfinderHeightConstraint])

        updateSubtitle()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let windowHeight = view.window?.bounds.height {
            maximumViewfinderHeightConstraint.constant = windowHeight * Self.maximumViewfinderHeightRatio
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasFinished else { return }
        startScanningAfterRequestingPermissionIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewfinderView.stopScanner()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        viewfinderView.deviceOrientation = UIDevice.current.orientation
    }

    // MARK: - Scanning

    private func startScanningAfterRequestingPermissionIfNeeded() {
        #if targetEnvironment(simulator)
        // The simulator has no camera, so skip the permission prompt and let the scanner report its error.
        viewfinderView.startScanner()
        #else
        guard AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined else {
            viewfinderView.startScanner()
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, !self.hasFinished, self.view.window != nil else { return }
                self.updateSubtitle()
                self.viewfinderView.startScanner()
            }
        }
        #endif
    }

    private func updateSubtitle() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            subtitleLabel.text = STPLocalizedString(
                "Hold your card with the number visible in the frame to scan it automatically.",
                "Instructions shown above the camera viewfinder while scanning a card."
            )
        } else {
            subtitleLabel.text = STPLocalizedString(
                "Allow camera permissions and get your card ready for scanning.",
                "Instructions shown above the camera viewfinder before the customer has given the app access to the camera."
            )
        }
    }

    @objc private func didTapManualEntry() {
        guard !hasFinished else { return }
        hasFinished = true
        viewfinderView.stopScanner()
        pop()
        delegate?.cardScanViewControllerDidSelectManualEntry(self)
    }

    /// Returns to the form.
    /// The sheet puts the form back on screen as soon as the pop begins, so the delegate is notified right after this, letting the form fill in and focus its fields (and bring up the keyboard) as part of the same transition.
    private func pop() {
        _ = bottomSheetController?.popContentViewController()
    }
}

// MARK: - CardScanViewfinderViewDelegate

@available(macCatalyst 14.0, *)
extension CardScanViewController: CardScanViewfinderViewDelegate {
    func cardScanViewfinderView(_ viewfinderView: CardScanViewfinderView, didScan cardParams: STPPaymentMethodCardParams) {
        guard !hasFinished else { return }
        hasFinished = true
        updateSubtitle()
        manualEntryButton.isEnabled = false
        // Let the customer see that the scan succeeded before showing the filled-in form.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.successDisplayDuration) { [weak self] in
            guard let self else { return }
            self.pop()
            self.delegate?.cardScanViewController(self, didScan: cardParams)
        }
    }

    func cardScanViewfinderViewDidError(_ viewfinderView: CardScanViewfinderView) {
        updateSubtitle()
    }
}

// MARK: - BottomSheetContentViewController

@available(macCatalyst 14.0, *)
extension CardScanViewController: BottomSheetContentViewController {
    var requiresFullScreen: Bool {
        return true
    }

    func didTapOrSwipeToDismiss() {
        underlyingContentViewController?.didTapOrSwipeToDismiss()
    }
}

// MARK: - SheetNavigationBarDelegate

@available(macCatalyst 14.0, *)
extension CardScanViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        underlyingContentViewController?.didTapOrSwipeToDismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        guard !hasFinished else { return }
        hasFinished = true
        viewfinderView.stopScanner()
        // Go back on the screen underneath first, so the sheet transitions straight to its previous screen instead of briefly showing the form.
        if let underlyingContentViewController {
            underlyingContentViewController.navigationBar.delegate?.sheetNavigationBarDidBack(underlyingContentViewController.navigationBar)
        }
        // Going back may have already removed this screen from the sheet.
        if bottomSheetController?.contentStack.first === self {
            pop()
        }
    }
}

#endif
