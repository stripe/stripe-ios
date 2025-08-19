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
@objc(OldSTP_Internal_CardSectionWithScannerView)
final class OldCardSectionWithScannerView: UIView {
    let cardSectionView: UIView
    let analyticsHelper: PaymentSheetAnalyticsHelper?
    lazy var cardScanButton: UIButton = {
        let button = UIButton.makeCardScanButton(theme: theme, linkAppearance: linkAppearance)
        button.addTarget(self, action: #selector(didTapCardScanButton), for: .touchUpInside)
        return button
    }()
    lazy var cardScanningView: OldCardScanningView = {
        let scanningView = OldCardScanningView()
        scanningView.isHidden = true
        scanningView.delegate = self
        return scanningView
    }()
    weak var delegate: OldCardSectionWithScannerViewDelegate?
    private let theme: ElementsAppearance
    private let linkAppearance: LinkAppearance?

    init(cardSectionView: UIView, delegate: OldCardSectionWithScannerViewDelegate, theme: ElementsAppearance = .default, analyticsHelper: PaymentSheetAnalyticsHelper?, linkAppearance: LinkAppearance? = nil) {
        self.cardSectionView = cardSectionView
        self.delegate = delegate
        self.theme = theme
        self.analyticsHelper = analyticsHelper
        self.linkAppearance = linkAppearance
        super.init(frame: .zero)
        installConstraints()
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
        setCardScanVisible(true)
        cardScanningView.start()
        becomeFirstResponder()
    }

    private func setCardScanVisible(_ isCardScanVisible: Bool) {
        if !isCardScanVisible {
            self.cardScanningView.prepDismissAnimation()
        }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
            self.cardScanButton.alpha = isCardScanVisible ? 0 : 1
            self.cardScanningView.setHiddenIfNecessary(!isCardScanVisible)
            self.layoutIfNeeded()
        } completion: { _ in
            if !isCardScanVisible {
                self.cardScanningView.completeDismissAnimation()
            }
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        cardScanningView.stop()
        return super.resignFirstResponder()
    }
}

@available(macCatalyst 14.0, *)
extension OldCardSectionWithScannerView: OldSTP_Internal_CardScanningViewDelegate {
    func cardScanningView(_ cardScanningView: OldCardScanningView, didFinishWith cardParams: STPPaymentMethodCardParams?) {
        setCardScanVisible(false)
        if let cardParams = cardParams {
            self.delegate?.didScanCard(self, cardParams: cardParams)
        }
    }
}

// MARK: - CardFormElementViewDelegate
protocol OldCardSectionWithScannerViewDelegate: AnyObject {
    func didScanCard(_ oldCardSectionWithScannerView: OldCardSectionWithScannerView, cardParams: STPPaymentMethodCardParams)
}

#endif
