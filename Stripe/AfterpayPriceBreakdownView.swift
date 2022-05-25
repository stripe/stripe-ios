//
//  AfterpayPriceBreakdownView.swift
//  StripeiOS
//
//  Created by Jaime Park on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import Foundation
import UIKit
import SafariServices
@_spi(STP) import StripeUICore

/// The view looks like:
///
/// Single row (width can contain all subviews):
///   Pay in 4 interest-free payments of %@ with [Afterpay logo] [info button]
///
/// Multi row (width can't contain all subviews):
///   Pay in 4 interest-free payments of %@ with
///   [Afterpay logo] [info button]
/// For internal SDK use only
@objc(STP_Internal_AfterpayPriceBreakdownView)
class AfterpayPriceBreakdownView: UIView {
    private let priceBreakdownLabel = UILabel()
    
    private lazy var afterpayMarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = STPImageLibrary.afterpayLogo(locale: locale)
        imageView.tintColor = ElementsUITheme.current.colors.parentBackground.contrastingColor

        return imageView
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton()
        button.setImage(STPImageLibrary.safeImageNamed("afterpay_icon_info@3x"), for: .normal)
        return button
    }()
    
    private lazy var infoURL: URL? = {
        let regionCode = Locale.current.regionCode ?? "us"
        return URL(string: "https://static-us.afterpay.com/javascript/modal/\(regionCode.lowercased())_rebrand_modal.html")
    }()

    let locale: Locale
    
    init(amount: Int, currency: String, locale: Locale = Locale.autoupdatingCurrent) {
        self.locale = locale
        super.init(frame: .zero)
        
        let installmentAmount = amount / 4
        let installmentAmountDisplayString = String.localizedAmountDisplayString(for: installmentAmount, currency: currency)
        
        priceBreakdownLabel.attributedText = generatePriceBreakdownString(installmentAmountString: installmentAmountDisplayString)
        
        [priceBreakdownLabel, afterpayMarkImageView, infoButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            priceBreakdownLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor),
            priceBreakdownLabel.topAnchor.constraint(
                equalTo: topAnchor),

            afterpayMarkImageView.bottomAnchor.constraint(
                equalTo: bottomAnchor),

            infoButton.leadingAnchor.constraint(
                equalTo: afterpayMarkImageView.trailingAnchor, constant: 7),
            infoButton.bottomAnchor.constraint(
                equalTo: bottomAnchor),
        ])
        
        infoButton.addTarget(self, action: #selector(didTapInfoButton), for: .touchUpInside)
    }
    
    override init(frame: CGRect) {
        self.locale = Locale.autoupdatingCurrent
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var singleRowConstraints: [NSLayoutConstraint] = [

        afterpayMarkImageView.leadingAnchor.constraint(
            equalTo: priceBreakdownLabel.trailingAnchor, constant: 5),
        afterpayMarkImageView.centerYAnchor.constraint(
            equalTo: priceBreakdownLabel.centerYAnchor),

        infoButton.centerYAnchor.constraint(
            equalTo: priceBreakdownLabel.centerYAnchor),
    ]

    private lazy var multiRowConstraints: [NSLayoutConstraint] = [

        afterpayMarkImageView.leadingAnchor.constraint(
            equalTo: leadingAnchor),
        afterpayMarkImageView.topAnchor.constraint(
            equalTo: priceBreakdownLabel.bottomAnchor, constant: 2),

        infoButton.centerYAnchor.constraint(
            equalTo: afterpayMarkImageView.centerYAnchor),
    ]
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !subviewsOutOfBounds() {
            NSLayoutConstraint.deactivate(multiRowConstraints)
            NSLayoutConstraint.activate(singleRowConstraints)
            super.layoutSubviews()
        } else {
            NSLayoutConstraint.deactivate(singleRowConstraints)
            NSLayoutConstraint.activate(multiRowConstraints)
            super.layoutSubviews()
        }
    }
    
    private func subviewsOutOfBounds() -> Bool {
        let subviewsTotalWidth = [priceBreakdownLabel, afterpayMarkImageView, infoButton].reduce(0) { $0 + $1.bounds.width }
        return subviewsTotalWidth >= bounds.width
    }
    
    private func generatePriceBreakdownString(installmentAmountString: String) -> NSMutableAttributedString {
        let amountStringAttributes = [
            NSAttributedString.Key.font: ElementsUITheme.current.fonts.subheadlineBold,
            .foregroundColor: ElementsUITheme.current.colors.bodyText
        ]
        
        let stringAttributes = [
            NSAttributedString.Key.font: ElementsUITheme.current.fonts.subheadline,
            .foregroundColor: ElementsUITheme.current.colors.bodyText
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
        if let url = infoURL {
            let safariController = SFSafariViewController(url: url)
            safariController.modalPresentationStyle = .overCurrentContext
            parentViewController?.present(safariController, animated: true)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        afterpayMarkImageView.tintColor = ElementsUITheme.current.colors.parentBackground.contrastingColor
    }
}

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
