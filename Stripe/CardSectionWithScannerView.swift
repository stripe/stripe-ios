//
//  CardElementView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 3/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

/**
 A view that wraps a normal section and adds a "Scan card" button. Tapping the button displays a card scan view below the section.
 */
/// For internal SDK use only
@objc(STP_Internal_CardSectionWithScannerView)
@available(iOS 13, macCatalyst 14, *)
final class CardSectionWithScannerView: UIView {
    let cardSectionView: UIView
    lazy var cardScanButton: UIButton = {
        let button = UIButton.makeCardScanButton()
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
    
    init(cardSectionView: UIView, delegate: CardSectionWithScannerViewDelegate) {
        self.cardSectionView = cardSectionView
        self.delegate = delegate
        super.init(frame: .zero)
        installConstraints()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    fileprivate func installConstraints() {
        let sectionTitle = ElementsUI.makeSectionTitleLabel()
        sectionTitle.text = String.Localized.card_information
        let cardSectionTitleAndButton = UIStackView(arrangedSubviews: [sectionTitle, cardScanButton])
        
        let stack = UIStackView(arrangedSubviews: [cardSectionTitleAndButton, cardSectionView, cardScanningView])
        stack.axis = .vertical
        stack.spacing = ElementsUI.sectionSpacing
        stack.setCustomSpacing(ElementsUI.formSpacing, after: cardSectionView)
        addAndPinSubview(stack)
    }
    
    @available(iOS 13, macCatalyst 14, *)
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

@available(iOS 13, macCatalyst 14, *)
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
