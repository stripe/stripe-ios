//
//  PaymentSheetVerticalViewController+AutomaticCardScan.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 11/3/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

#if !os(visionOS)
/// When `opensCardScannerAutomatically` is enabled, the card form first shows only a large scanner (`AutomaticCardScanViewController`),
/// with an "Enter card details manually" button in place of the primary button.
/// Scanning a card or tapping that button swaps the card form back in; a "Scan card" button in the form header reopens the scanner.
extension PaymentSheetVerticalViewController {

    /// Whether the card form uses `AutomaticCardScanViewController` instead of its inline scanner.
    var usesAutomaticCardScanner: Bool {
        return configuration.opensCardScannerAutomatically && STPCardScanner.cardScanningAvailable
    }

    var isShowingAutomaticCardScanner: Bool {
        guard let automaticCardScanViewController else { return false }
        return children.contains(automaticCardScanViewController)
    }

    /// Whether a newly displayed form for `paymentMethodType` should start with the scanner.
    /// It does unless the customer chose to enter their card manually, already scanned a card, or is returning to card details they entered before.
    func shouldAutomaticallyShowCardScanner(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        return paymentMethodType == .stripe(.card)
            && usesAutomaticCardScanner
            && !prefersCardFormOverScanner
            && previousFormConfirmParams?.paymentMethodType != .stripe(.card)
    }

    /// Makes the "Scan card" button for the card form's header, if the form uses the automatic scanner.
    func makeHeaderCardScanButton(for paymentMethodType: PaymentSheet.PaymentMethodType) -> UIView? {
        guard paymentMethodType == .stripe(.card), usesAutomaticCardScanner else { return nil }
        let button = AutomaticCardScanViewController.HeaderScanButton(appearance: configuration.appearance)
        button.addTarget(self, action: #selector(didTapHeaderCardScanButton), for: .touchUpInside)
        return button
    }

    /// Routes the card form's scan button to the automatic scanner instead of its inline scanner.
    func configureAutomaticCardScanner(for formViewController: PaymentMethodFormViewController) {
        guard formViewController.paymentMethodType == .stripe(.card), usesAutomaticCardScanner else { return }
        // If the header can't show the scan button (e.g. it shows wallet buttons instead), keep the form's own scan button.
        let headerShowsScanButton = (formViewController.headerView as? FormHeaderView)?.accessoryView != nil
        formViewController.cardSectionElement?.useExternalCardScanner(showsScanButton: !headerShowsScanButton) { [weak self] in
            self?.prefersCardFormOverScanner = false
            self?.showAutomaticCardScanner(animated: true)
        }
    }

    /// Adds the "Enter card details manually" button over the primary button.
    func installManualCardEntryButton() {
        guard usesAutomaticCardScanner else { return }
        manualCardEntryButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(manualCardEntryButton)
        NSLayoutConstraint.activate([
            manualCardEntryButton.topAnchor.constraint(equalTo: primaryButton.topAnchor),
            manualCardEntryButton.leadingAnchor.constraint(equalTo: primaryButton.leadingAnchor),
            manualCardEntryButton.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor),
            manualCardEntryButton.bottomAnchor.constraint(equalTo: primaryButton.bottomAnchor),
        ])
        updateManualCardEntryButton(animated: false)
    }

    /// Crossfades between the primary button and the "Enter card details manually" button.
    func updateManualCardEntryButton(animated: Bool = true) {
        guard usesAutomaticCardScanner else { return }
        let isShowingScanner = isShowingAutomaticCardScanner
        primaryButton.isUserInteractionEnabled = !isShowingScanner
        primaryButton.accessibilityElementsHidden = isShowingScanner
        manualCardEntryButton.isUserInteractionEnabled = isShowingScanner
        manualCardEntryButton.accessibilityElementsHidden = !isShowingScanner
        let updateAlpha = {
            self.primaryButton.alpha = isShowingScanner ? 0 : 1
            self.manualCardEntryButton.alpha = isShowingScanner ? 1 : 0
        }
        if animated && view.window != nil {
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration, delay: 0, options: [.beginFromCurrentState], animations: updateAlpha)
        } else {
            updateAlpha()
        }
    }

    /// Shows the scanner in place of the card form.
    /// - Parameter animated: Whether to crossfade from the current content. Pass `false` before the view is displayed.
    func showAutomaticCardScanner(animated: Bool) {
        guard usesAutomaticCardScanner, !isShowingAutomaticCardScanner else { return }
        let headerView = FormHeaderView(
            paymentMethodType: .stripe(.card),
            shouldUseNewCardHeader: savedPaymentMethods.first?.type == .card,
            appearance: configuration.appearance,
            currency: intent.currency,
            incentive: nil
        )
        let scanViewController = AutomaticCardScanViewController(
            headerView: headerView,
            appearance: configuration.appearance,
            delegate: self
        )
        automaticCardScanViewController = scanViewController
        if animated {
            // Dismiss the keyboard alongside the transition
            view.endEditing(true)
            switchAutomaticCardScanContent(to: scanViewController)
        } else {
            add(childViewController: scanViewController, containerView: paymentContainerView)
        }
        updateUI()
    }

    /// Swaps the card form back in place of the scanner.
    private func hideAutomaticCardScanner() {
        guard let paymentMethodFormViewController, isShowingAutomaticCardScanner else { return }
        automaticCardScanViewController?.stopScanning()
        switchAutomaticCardScanContent(to: paymentMethodFormViewController)
        updateUI()
    }

    /// Like `switchContentIfNecessary`, but fades the old content out before fading the new content in.
    /// The scanner and the card form both start with the same header at different heights within the sheet, so a simultaneous
    /// crossfade would briefly show two headers while the sheet resizes.
    private func switchAutomaticCardScanContent(to toVC: UIViewController) {
        guard let fromVC = children.first, fromVC !== toVC else { return }
        toVC.beginAppearanceTransition(true, animated: true)
        addChild(toVC)
        toVC.view.alpha = 0
        paymentContainerView.addPinnedSubview(toVC.view)
        paymentContainerView.layoutIfNeeded()  // Lay the view out now or it animates layout from a zero size

        // Remove the child view controller, but keep its view on screen so we can fade it out
        fromVC.willMove(toParent: nil)
        fromVC.removeFromParent()

        UIView.animate(withDuration: 0.15, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
            fromVC.view.alpha = 0
        }
        UIView.animate(withDuration: 0.25, delay: 0.1, options: [.curveEaseInOut]) {
            toVC.view.alpha = 1
        }
        animateHeightChange(
            {
                self.paymentContainerView.updateHeight()
                toVC.didMove(toParent: self)
            },
            postLayoutAnimations: {
                self.bottomSheetController?.invalidateContentDetent()
            },
            completion: { _ in
                toVC.endAppearanceTransition()
                fromVC.view.removeFromSuperview()
                fromVC.didMove(toParent: nil)
                UIAccessibility.post(notification: .screenChanged, argument: toVC.view)
            }
        )
    }

    @objc func didTapManualCardEntryButton() {
        prefersCardFormOverScanner = true
        analyticsHelper.logFormInteracted(paymentMethodTypeIdentifier: PaymentSheet.PaymentMethodType.stripe(.card).identifier)
        hideAutomaticCardScanner()
        // Focus the card number so the keyboard rises while the form fades in
        _ = paymentMethodFormViewController?.cardSectionElement?.panElement.beginEditing()
    }

    @objc private func didTapHeaderCardScanButton() {
        prefersCardFormOverScanner = false
        showAutomaticCardScanner(animated: true)
    }
}

// MARK: - AutomaticCardScanViewControllerDelegate

extension PaymentSheetVerticalViewController: AutomaticCardScanViewControllerDelegate {
    func automaticCardScanViewController(_ viewController: AutomaticCardScanViewController, didScan cardParams: STPPaymentMethodCardParams) {
        guard viewController === automaticCardScanViewController, let paymentMethodFormViewController else { return }
        // Keep showing the scanned details if the customer leaves and comes back to the card form
        prefersCardFormOverScanner = true
        hideAutomaticCardScanner()
        // Fill in the form after it's on screen, so focus can move to the first empty field (usually the CVC)
        paymentMethodFormViewController.cardSectionElement?.didScanCard(cardParams: cardParams)
        ((paymentMethodFormViewController.headerView as? FormHeaderView)?.accessoryView as? AutomaticCardScanViewController.HeaderScanButton)?.hasScannedCard = true
    }
}

#else
// Card scanning isn't available on visionOS
extension PaymentSheetVerticalViewController {
    var isShowingAutomaticCardScanner: Bool { false }
    func shouldAutomaticallyShowCardScanner(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool { false }
    func showAutomaticCardScanner(animated: Bool) {}
    func makeHeaderCardScanButton(for paymentMethodType: PaymentSheet.PaymentMethodType) -> UIView? { nil }
    func configureAutomaticCardScanner(for formViewController: PaymentMethodFormViewController) {}
    func installManualCardEntryButton() {}
    func updateManualCardEntryButton(animated: Bool = true) {}
}
#endif

// MARK: - PaymentMethodFormViewController

extension PaymentMethodFormViewController {
    var cardSectionElement: CardSectionElement? {
        return form.getAllUnwrappedSubElements().compactMap { $0 as? CardSectionElement }.first
    }
}
