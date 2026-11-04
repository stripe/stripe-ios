//
//  CardSectionWithScannerView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)
import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments
@_spi(InternalOnlyAPI) import StripePaymentsUI
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/**
 A view that wraps a normal section and adds a "Scan card" button. Tapping the button displays a card scan view below the section.
 If the scanner opens automatically, the section instead pushes a full-height `CardScanViewController` when it first appears, and the button reopens that screen.
 */
/// For internal SDK use only
@available(macCatalyst 14.0, *)
@objc(STP_Internal_CardSectionWithScannerView)
final class CardSectionWithScannerView: UIView {

    let cardSectionView: UIView
    let analyticsHelper: PaymentSheetAnalyticsHelper?
    lazy var cardScanButton: UIButton = {
        let button = opensCardScannerAutomatically
            ? UIButton.makeCardScanPillButton(theme: theme, linkAppearance: linkAppearance)
            : UIButton.makeCardScanButton(theme: theme, linkAppearance: linkAppearance)
        button.addTarget(self, action: #selector(didTapCardScanButton), for: .touchUpInside)
        return button
    }()
    lazy var cardScanningView: CardScanningView = {
        let scanningView = CardScanningView(theme: theme)
        scanningView.delegate = self
        return scanningView
    }()
    private let opensCardScannerAutomatically: Bool
    private var hasOpenedCardScannerAutomatically = false
    /// Work to do once the form is back on screen after the card scan screen pops, e.g. filling in the scanned card.
    private var actionWhenVisible: (() -> Void)?
    weak var delegate: CardSectionWithScannerViewDelegate?
    private let theme: ElementsAppearance
    private let linkAppearance: LinkAppearance?

    init(
        cardSectionView: UIView,
        opensCardScannerAutomatically: Bool,
        delegate: CardSectionWithScannerViewDelegate,
        theme: ElementsAppearance = .default,
        analyticsHelper: PaymentSheetAnalyticsHelper?,
        linkAppearance: LinkAppearance? = nil
    ) {
        self.cardSectionView = cardSectionView
        self.opensCardScannerAutomatically = opensCardScannerAutomatically
        self.delegate = delegate
        self.theme = theme
        self.analyticsHelper = analyticsHelper
        self.linkAppearance = linkAppearance
        super.init(frame: .zero)
        installConstraints()
        cardScanningView.setHiddenIfNecessary(true)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    fileprivate func installConstraints() {
        let sectionTitle = ElementsUI.makeSectionTitleLabel(theme: theme)
        sectionTitle.text = String.Localized.card_information
        let cardSectionTitleAndButton = UIStackView(arrangedSubviews: [sectionTitle, cardScanButton])
        if opensCardScannerAutomatically {
            cardSectionTitleAndButton.alignment = .center
        }

        let stack = UIStackView(arrangedSubviews: [cardSectionTitleAndButton, cardSectionView, cardScanningView])
        stack.axis = .vertical
        stack.spacing = ElementsUI.sectionElementInternalSpacing
        stack.setCustomSpacing(ElementsUI.formSpacing, after: cardSectionView)
        addAndPinSubview(stack)
    }

    @objc func didTapCardScanButton() {
        analyticsHelper?.logFormInteracted(paymentMethodTypeIdentifier: "card")
        if opensCardScannerAutomatically && pushCardScanViewController() {
            return
        }
        showInlineCardScanner()
    }

    private func showInlineCardScanner() {
        animateScannerVisibility(true)
        cardScanningView.startScanner()
        becomeFirstResponder()
    }

    /// Pushes the full-height card scan screen on top of the sheet's current content.
    /// - Returns: `false` if this view isn't hosted in a sheet, in which case nothing happens.
    @discardableResult
    private func pushCardScanViewController() -> Bool {
        guard window != nil, let bottomSheetController = findViewController(for: self)?.bottomSheetController else {
            return false
        }
        // Dismiss the keyboard so it doesn't cover the scanner
        endEditing(true)
        let cardScanViewController = CardScanViewController(
            appearance: bottomSheetController.appearance,
            theme: theme,
            underlyingContentViewController: bottomSheetController.contentStack.first
        )
        cardScanViewController.delegate = self
        bottomSheetController.pushContentViewController(cardScanViewController)
        return true
    }

    private func hideCardScanner() {
        self.cardScanningView.prepDismissAnimation()
        animateScannerVisibility(false) { _ in
            self.cardScanningView.completeDismissAnimation()
        }
    }

    private func animateScannerVisibility(_ isVisible: Bool, completion: ((Bool) -> Void)? = nil) {
        let nativeSheet = findViewController(for: self)?.bottomSheetController as? NativeSheetContainerViewController
        let targetHeight = nativeSheet?.fittedContentHeight(with: cardScanningView, isHidden: !isVisible)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: 0.3,
            options: [.curveEaseInOut],
            animations: {
                self.cardScanButton.alpha = isVisible ? 0 : 1
                self.cardScanningView.alpha = isVisible ? 1 : 0
                self.cardScanningView.setHiddenIfNecessary(!isVisible)
                self.layoutIfNeeded()
                if let nativeSheet, let targetHeight {
                    nativeSheet.invalidateContentDetent(to: targetHeight)
                }
            },
            completion: completion
        )
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        // If we leave the screen or an input field is focused, we close the scanner
        cardScanningView.stopScanner()
        hideCardScanner()
        return super.resignFirstResponder()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil, let actionWhenVisible {
            self.actionWhenVisible = nil
            actionWhenVisible()
        }
        // We wait until we are added to the screen to open the scanner instead of at initialization.
        // We only do this once, so returning to the form from the scanner doesn't reopen it.
        guard opensCardScannerAutomatically, window != nil, !hasOpenedCardScannerAutomatically else {
            return
        }
        hasOpenedCardScannerAutomatically = true
        // Wait for the in-progress layout or transition that added us to the window to finish before pushing a new screen.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.window != nil else { return }
            if !self.pushCardScanViewController() {
                self.showInlineCardScanner()
            }
        }
    }
}

// MARK: - CardScanViewControllerDelegate

@available(macCatalyst 14.0, *)
extension CardSectionWithScannerView: CardScanViewControllerDelegate {
    func cardScanViewController(_ viewController: CardScanViewController, didScan cardParams: STPPaymentMethodCardParams) {
        cardScanButton.configuration?.title = String.Localized.rescan_card
        performWhenVisible { [weak self] in
            self?.delegate?.didScanCard(cardParams: cardParams)
        }
    }

    func cardScanViewControllerDidSelectManualEntry(_ viewController: CardScanViewController) {
        performWhenVisible { [weak self] in
            self?.delegate?.didSelectManualCardEntry()
        }
    }

    /// Fields can only be focused while on screen. The sheet usually puts the form back on screen as soon as the scan screen starts popping,
    /// so this runs immediately and the keyboard comes up during the same transition. Otherwise, it waits for the form to reappear.
    private func performWhenVisible(_ action: @escaping () -> Void) {
        if window != nil {
            action()
        } else {
            actionWhenVisible = action
        }
    }
}

@available(macCatalyst 14.0, *)
extension CardSectionWithScannerView: STP_Internal_CardScanningViewDelegate {
    func cardScanningViewShouldClose(_ cardScanningView: CardScanningView, cardParams: StripePayments.STPPaymentMethodCardParams?) {
        hideCardScanner()
        if let cardParams {
            self.delegate?.didScanCard(cardParams: cardParams)
        }
    }
}

// MARK: - CardFormElementViewDelegate
protocol CardSectionWithScannerViewDelegate: AnyObject {
    func didScanCard(cardParams: STPPaymentMethodCardParams)
    func didSelectManualCardEntry()
}

#endif
