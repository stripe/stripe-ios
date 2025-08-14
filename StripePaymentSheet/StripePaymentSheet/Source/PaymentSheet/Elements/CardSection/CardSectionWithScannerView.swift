//
//  CardSectionWithScannerView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

#if !os(visionOS)
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/**
 A view that wraps a normal section and adds a "Scan card" button. Tapping the button displays a card scan view below the section.
 */
/// For internal SDK use only
@available(macCatalyst 14.0, *)
@objc(STP_Internal_CardSectionWithScannerView)
final class CardSectionWithScannerView: UIView {
    let cardSectionView: UIView
    private let opensCardScannerAutomatically: Bool
    let analyticsHelper: PaymentSheetAnalyticsHelper?
    lazy var cardScanButton: UIButton = {
        let button = UIButton.makeCardScanButton(theme: theme, linkAppearance: linkAppearance)
        button.addTarget(self, action: #selector(didTapCardScanButton), for: .touchUpInside)
        return button
    }()
    lazy var cardScanningView: CardScanningView = {
        let scanningView = CardScanningView()
        scanningView.delegate = self
        return scanningView
    }()
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

        if opensCardScannerAutomatically {
            // when the cardScanButton is disabled, we just set the alpha to 0
            // this makes animations easier than removing it with isHidden
            cardScanButton.alpha = 0
        } else {
            cardScanningView.isHidden = true
        }

        // add observer for keyboard so that we can hide the card scanner when the keyboard appears
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideCardScanner),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        // We wait until the view is added to the window to start the scanner
        //  since it may be initialized without being displayed
        if newWindow == nil {
            // If the view is being removed, we stop the scanner
            cardScanningView.stopScanner()
        } else if cardScanningView.isHidden == false {
            // If the view is being added and the scanner is visible, we start the scanner
            cardScanningView.startScanner()
        }
        super.willMove(toWindow: newWindow)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    fileprivate func installConstraints() {
        let sectionTitle = ElementsUI.makeSectionTitleLabel(theme: theme)
        sectionTitle.text = String.Localized.card_information
        let cardSectionTitleAndButton = UIStackView(arrangedSubviews: [sectionTitle, cardScanButton])

        let stack = UIStackView(arrangedSubviews: [cardSectionTitleAndButton, cardSectionView, cardScanningView])
        stack.axis = .vertical
        stack.spacing = ElementsUI.sectionElementInternalSpacing
        stack.setCustomSpacing(ElementsUI.formSpacing, after: cardSectionView)
        addAndPinSubview(stack)
    }

    @objc func didTapCardScanButton() {
        analyticsHelper?.logFormInteracted(paymentMethodTypeIdentifier: "card")
        showCardScanner()
        cardScanningView.startScanner()
        // hide keyboard
        becomeFirstResponder()
    }

    @objc private func hideCardScanner() {
        // Disregard is the scanner is already hidden
        guard self.cardScanningView.isHidden == false else {
            return
        }
        self.cardScanningView.prepDismissAnimation()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.cardScanButton.alpha = 1
            self.cardScanningView.setHiddenIfNecessary(true)
            self.layoutIfNeeded()
        } completion: { _ in
            self.cardScanningView.completeDismissAnimation()
        }
    }

    private func showCardScanner() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.cardScanButton.alpha = 0
            self.cardScanningView.setHiddenIfNecessary(false)
            self.layoutIfNeeded()
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}

@available(macCatalyst 14.0, *)
extension CardSectionWithScannerView: STP_Internal_CardScanningViewDelegate {

    func cardScanningViewShouldClose(_ cardScanningView: CardScanningView) {
        hideCardScanner()
    }

    func cardScanningView(_ cardScanningView: CardScanningView, didScanCard cardParams: STPPaymentMethodCardParams) {
        self.delegate?.didScanCard(cardParams: cardParams)
    }
}

// MARK: - CardFormElementViewDelegate
protocol CardSectionWithScannerViewDelegate: AnyObject {
    // Called when a card is scanned successfully
    func didScanCard(cardParams: STPPaymentMethodCardParams)
}

#endif
