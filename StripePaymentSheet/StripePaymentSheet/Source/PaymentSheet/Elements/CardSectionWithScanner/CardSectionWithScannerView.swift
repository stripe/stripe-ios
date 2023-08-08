//
//  CardSectionWithScannerView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

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
    lazy var cardScanButton: UIButton = {
        let button = UIButton.makeCardScanButton(theme: theme)
        button.addTarget(self, action: #selector(didTapCardScanButton), for: .touchUpInside)
        return button
    }()
    lazy var cardScanningView: CardScanningView = {
        let scanningView = CardScanningView()
        scanningView.alpha = 0
        scanningView.isHidden = true
        scanningView.delegate = self
        return scanningView
    }()
    weak var delegate: CardSectionWithScannerViewDelegate?
    private let theme: ElementsUITheme

    init(cardSectionView: UIView, delegate: CardSectionWithScannerViewDelegate, theme: ElementsUITheme = .default) {
        self.cardSectionView = cardSectionView
        self.delegate = delegate
        self.theme = theme
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
        stack.spacing = ElementsUI.sectionSpacing
        stack.setCustomSpacing(ElementsUI.formSpacing, after: cardSectionView)
        addAndPinSubview(stack)
    }

    @objc func didTapCardScanButton() {
        setCardScanVisible(true)
        cardScanningView.start()
        becomeFirstResponder()
    }

    private func setCardScanVisible(_ isCardScanVisible: Bool) {
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.cardScanButton.alpha = isCardScanVisible ? 0 : 1
            self.cardScanningView.isHidden = !isCardScanVisible
            self.cardScanningView.alpha = isCardScanVisible ? 1 : 0
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
extension CardSectionWithScannerView: STP_Internal_CardScanningViewDelegate {
    func cardScanningView(_ cardScanningView: CardScanningView, didFinishWith cardParams: STPPaymentMethodCardParams?) {
        setCardScanVisible(false)
        if let cardParams = cardParams {
            self.delegate?.didScanCard(cardParams: cardParams)
        }
    }
}

// MARK: - CardFormElementViewDelegate
protocol CardSectionWithScannerViewDelegate: AnyObject {
    func didScanCard(cardParams: STPPaymentMethodCardParams)
}
