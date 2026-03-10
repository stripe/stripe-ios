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
        return NSMutableAttributedString.afterpayPromoString(
            font: appearance.asElementsTheme.fonts.subheadline,
            textColor: appearance.colors.text,
            template: template,
            logo: afterpayMarkImage
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

private extension NSMutableAttributedString {
    /// Generates an attributed string for Afterpay promo text with an info icon at the end.
    static func afterpayPromoString(
        font: UIFont,
        textColor: UIColor,
        template: String,
        logo: UIImage
    ) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        let stringAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        let resultingString = NSMutableAttributedString()
        let placeholder = "<img/>"

        guard let imgRange = template.range(of: placeholder) else {
            resultingString.append(NSAttributedString(string: template, attributes: stringAttributes))
            return resultingString
        }

        var imgAppended = false

        // Go through string, replacing the placeholder with the logo
        for (indexOffset, currCharacter) in template.enumerated() {
            let currIndex = template.index(template.startIndex, offsetBy: indexOffset)
            if imgRange.contains(currIndex) {
                if imgAppended {
                    continue
                }
                imgAppended = true

                // Add logo with 2x scale
                let logoAttr = NSAttributedString.attributedStringForImage(logo, font: font, additionalScale: 2.0)
                resultingString.append(logoAttr)
            } else {
                resultingString.append(NSAttributedString(string: String(currCharacter), attributes: stringAttributes))
            }
        }

        // Add info icon with 1.5x scale
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize)
        if let infoIconImage = UIImage(systemName: "info.circle", withConfiguration: symbolConfig)?
            .withTintColor(textColor, renderingMode: .alwaysTemplate) {
            let infoIcon = NSAttributedString.attributedStringForImage(infoIconImage, font: font, additionalScale: 1.5)
            resultingString.append(NSAttributedString(string: "\u{00A0}", attributes: stringAttributes))
            resultingString.append(infoIcon)
        } else {
            stpAssertionFailure("Failed to load system image info.circle")
        }

        return resultingString
    }
}
