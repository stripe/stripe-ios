//
//  AfterpayPriceBreakdownView.swift
//  StripeiOS
//
//  Created by Jaime Park on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import Foundation
import UIKit

/// The view looks like:
///
/// Single row (width can contain all subviews):
///   Pay in 4 interest-free payments of %@ with [Afterpay logo] [info button]
///
/// Multi row (width can't contain all subviews):
///   Pay in 4 interest-free payments of %@ with
///   [Afterpay logo] [info button]

class AfterpayPriceBreakdownView: UIView {
    private let priceBreakdownLabel = UILabel()
    
    private lazy var afterpayMarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = STPImageLibrary.afterpayLogo()
        return imageView
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton()
        button.setImage(STPImageLibrary.safeImageNamed("afterpay_icon_info@3x"), for: .normal)
        return button
    }()
    
    convenience init(amount: Int, currency: String) {
        self.init(frame: .zero)
        
        let installmentAmount = amount / 4
        let installmentAmountDisplayString = String.localizedAmountDisplayString(for: installmentAmount, currency: currency)
        
        priceBreakdownLabel.attributedText = generatePriceBreakdownString(installmentAmountString: installmentAmountDisplayString)
        
        [priceBreakdownLabel, afterpayMarkImageView, infoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        infoButton.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let singleRowConstraints = [
            priceBreakdownLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor),
            priceBreakdownLabel.topAnchor.constraint(
                equalTo: topAnchor),
            
            afterpayMarkImageView.leadingAnchor.constraint(
                equalTo: priceBreakdownLabel.trailingAnchor, constant: 5),
            afterpayMarkImageView.centerYAnchor.constraint(
                equalTo: priceBreakdownLabel.centerYAnchor),
            afterpayMarkImageView.bottomAnchor.constraint(
                equalTo: bottomAnchor),
            
            infoButton.leadingAnchor.constraint(
                equalTo: afterpayMarkImageView.trailingAnchor, constant: 7),
            infoButton.centerYAnchor.constraint(
                equalTo: priceBreakdownLabel.centerYAnchor),
            infoButton.bottomAnchor.constraint(
                equalTo: bottomAnchor)
        ]
        
        let multiRowConstraints = [
            priceBreakdownLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor),
            priceBreakdownLabel.topAnchor.constraint(
                equalTo: topAnchor),
            
            afterpayMarkImageView.leadingAnchor.constraint(
                equalTo: leadingAnchor),
            afterpayMarkImageView.topAnchor.constraint(
                equalTo: priceBreakdownLabel.bottomAnchor, constant: 2),
            afterpayMarkImageView.bottomAnchor.constraint(
                equalTo: bottomAnchor),
                                    
            infoButton.leadingAnchor.constraint(
                equalTo: afterpayMarkImageView.trailingAnchor, constant: 7),
            infoButton.centerYAnchor.constraint(
                equalTo: afterpayMarkImageView.centerYAnchor),
            infoButton.bottomAnchor.constraint(
                equalTo: bottomAnchor)
        ]
        
        if !subviewsOutOfBounds() {
            NSLayoutConstraint.activate(singleRowConstraints)
        } else {
            NSLayoutConstraint.activate(multiRowConstraints)
        }
    }
    
    private func subviewsOutOfBounds() -> Bool {
        let subviewsTotalWidth = [priceBreakdownLabel, afterpayMarkImageView, infoButton].reduce(0) { $0 + $1.bounds.width }
        return subviewsTotalWidth >= bounds.width
    }
    
    private func generatePriceBreakdownString(installmentAmountString: String) -> NSMutableAttributedString {
        let amountStringAttributes = [
            NSAttributedString.Key.font:
                UIFontMetrics(forTextStyle: .subheadline)
                    .scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .bold))
        ]
        
        let stringAttributes = [
            NSAttributedString.Key.font:
                UIFontMetrics(forTextStyle: .subheadline)
                .scaledFont(for: UIFont.systemFont(ofSize: 14, weight: .regular))
        ]
        
        let amountString = NSMutableAttributedString(
            string: "\(installmentAmountString) ",
            attributes: amountStringAttributes
        )

        let payIn4String = NSMutableAttributedString(
            string: "Pay in 4 interest-free payments of ",
            attributes: stringAttributes
        )
        
        let withString = NSMutableAttributedString(
            string: "with",
            attributes: stringAttributes
        )
        
        payIn4String.append(amountString)
        payIn4String.append(withString)
        
        return payIn4String
    }
    
    @objc
    private func didTapInfoButton() {
        // TODO: Put info button action
    }
}
