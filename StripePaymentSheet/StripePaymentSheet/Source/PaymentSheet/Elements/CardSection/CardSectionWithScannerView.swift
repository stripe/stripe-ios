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
    let analyticsHelper: PaymentSheetAnalyticsHelper?
    lazy var cardScanButton: UIButton = {
        let button = UIButton.makeCardScanButton(theme: theme, linkAppearance: linkAppearance)
        button.addTarget(self, action: #selector(didTapCardScanButton), for: .touchUpInside)
        return button
    }()
    lazy var cardScanningView: CardScanningView = {
        let scanningView = CardScanningView(theme: theme)
        scanningView.delegate = self
        return scanningView
    }()
    private let opensCardScannerAutomatically: Bool
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
            cardScanButton.alpha = 0
        } else {
            cardScanningView.setHiddenIfNecessary(true)
        }
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
        becomeFirstResponder()
    }

    private func hideCardScanner() {
        self.cardScanningView.prepDismissAnimation()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.cardScanButton.alpha = 1
            self.cardScanningView.alpha = 0
            self.cardScanningView.setHiddenIfNecessary(true)
            self.layoutIfNeeded()
        } completion: { _ in
            self.cardScanningView.completeDismissAnimation()
        }
    }

    private func showCardScanner() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.cardScanButton.alpha = 0
            self.cardScanningView.alpha = 1
            self.cardScanningView.setHiddenIfNecessary(false)
            self.layoutIfNeeded()
        }
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

    override func willMove(toWindow newWindow: UIWindow?) {
        // We wait until we are added to the screen to start the scanner instead of at initialization
        // If cardScanningView.start() is called when it is already started, nothing will happen
        // The opensCardScannerAutomatically check is redudant since this should only apply in that case,
        //    but it adds a bit of extra safety. This can be removed in the future.
        if newWindow != nil && !cardScanningView.isHidden && opensCardScannerAutomatically {
            cardScanningView.startScanner()
            becomeFirstResponder()
        }
        super.willMove(toWindow: newWindow)
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
}

#endif
