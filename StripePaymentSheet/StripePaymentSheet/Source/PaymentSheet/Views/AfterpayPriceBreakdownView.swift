//
//  AfterpayPriceBreakdownView.swift
//  StripePaymentSheet
//
//  Created by Jaime Park on 6/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_AfterpayPriceBreakdownView)
class AfterpayPriceBreakdownView: UIView {
    private let afterPayClearPayLabel = UILabel()
    private let appearance: PaymentSheet.Appearance
    private lazy var afterpayMarkImage: UIImage = {
        return PaymentSheetImageLibrary.afterpayLogo(currency: currency)
    }()

    private lazy var infoURL: URL? = {
        let language = locale.stp_languageCode?.lowercased() ?? "en"
        let region = locale.stp_regionCode?.uppercased() ?? "US"
        let localeCode = "\(language)_\(region)"
        return URL(string: "https://static.afterpay.com/modal/\(localeCode).html")
    }()

    let locale: Locale
    let currency: String?

    init(locale: Locale = Locale.autoupdatingCurrent, currency: String?, appearance: PaymentSheet.Appearance = .default) {
        self.locale = locale
        self.currency = currency
        self.appearance = appearance
        super.init(frame: .zero)

        afterPayClearPayLabel.attributedText = makeAfterPayClearPayString()
        afterPayClearPayLabel.numberOfLines = 0
        afterPayClearPayLabel.translatesAutoresizingMaskIntoConstraints = false
        afterPayClearPayLabel.isUserInteractionEnabled = true
        addSubview(afterPayClearPayLabel)

        NSLayoutConstraint.activate([
            afterPayClearPayLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor),
            afterPayClearPayLabel.topAnchor.constraint(
                equalTo: topAnchor),
            afterPayClearPayLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            afterPayClearPayLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        afterPayClearPayLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapInfoButton)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeAfterPayClearPayString() -> NSMutableAttributedString {
        let template = STPLocalizedString(
            "Buy now or pay later with  <img/>",
            "Promotional text for Afterpay/Clearpay - the image tag will display the Afterpay or Clearpay logo. This text is displayed in a button that lets the customer pay with Afterpay/Clearpay"
        )
        return NSMutableAttributedString.bnplPromoString(
            font: appearance.asElementsTheme.fonts.subheadline,
            textColor: appearance.colors.text,
            infoIconColor: appearance.colors.text,
            template: template,
            substitution: ("<img/>", afterpayMarkImage)
        )
    }

    @objc
    private func didTapInfoButton() {
        if let url = infoURL {
            let safariController = SFSafariViewController(url: url)
            safariController.modalPresentationStyle = .formSheet
            parentViewController?.present(safariController, animated: true)
        }
    }

#if !os(visionOS)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        afterPayClearPayLabel.attributedText = makeAfterPayClearPayString()
    }
#endif

    static func shouldUseClearpayBrand(for currency: String?) -> Bool {
        // See https://github.com/search?q=repo%3Aafterpay%2Fsdk-ios%20clearpay&type=code for latest rules
        return currency?.lowercased() == "gbp"
    }

    static func shouldUseCashAppBrand(for currency: String?) -> Bool {
        return currency?.lowercased() == "usd"
    }
}

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
