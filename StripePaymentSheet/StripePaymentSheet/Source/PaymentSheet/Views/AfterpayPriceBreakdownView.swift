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

        let font = appearance.asElementsTheme.fonts.subheadline
        let textColor = appearance.colors.text

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
            return resultingString
        }

        var imgAppended = false
        for (indexOffset, currCharacter) in template.enumerated() {
            let currIndex = template.index(template.startIndex, offsetBy: indexOffset)
            if imgRange.contains(currIndex) {
                if imgAppended {
                    continue
                }
                imgAppended = true
                let logoAttachment = NSTextAttachment()
                let scaledSize = afterpayMarkImage.sizeMatchingFont(font, additionalScale: 2.0)
                let heightDifference = font.capHeight - scaledSize.height
                let verticalOffset = heightDifference.rounded() / 2
                logoAttachment.bounds = CGRect(origin: .init(x: 0, y: verticalOffset), size: scaledSize)
                logoAttachment.image = afterpayMarkImage
                resultingString.append(NSAttributedString(attachment: logoAttachment))
            } else {
                resultingString.append(NSAttributedString(string: String(currCharacter), attributes: stringAttributes))
            }
        }

        // Add info icon
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: font.pointSize)
        if let infoIconImage = UIImage(systemName: "info.circle", withConfiguration: symbolConfig)?
            .withTintColor(textColor, renderingMode: .alwaysTemplate) {
            let infoAttachment = NSTextAttachment()
            let scaledSize = infoIconImage.sizeMatchingFont(font, additionalScale: 1.5)
            let heightDifference = font.capHeight - scaledSize.height
            let verticalOffset = heightDifference.rounded() / 2
            infoAttachment.bounds = CGRect(origin: .init(x: 0, y: verticalOffset), size: scaledSize)
            infoAttachment.image = infoIconImage
            resultingString.append(NSAttributedString(string: "\u{00A0}", attributes: stringAttributes))
            resultingString.append(NSAttributedString(attachment: infoAttachment))
        } else {
            stpAssertionFailure("Failed to load system image info.circle")
        }

        return resultingString
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
