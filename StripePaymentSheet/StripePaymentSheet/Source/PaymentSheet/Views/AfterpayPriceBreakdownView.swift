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
    private let theme: ElementsAppearance
    private lazy var afterpayMarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = PaymentSheetImageLibrary.afterpayLogo(locale: locale)
        imageView.tintColor = theme.colors.parentBackground.contrastingColor

        return imageView
    }()
    private lazy var afterpayMarkImage: UIImage = {
        return PaymentSheetImageLibrary.afterpayLogo(locale: locale)
    }()
    private lazy var infoImage: UIImage = {
        return PaymentSheetImageLibrary.safeImageNamed("afterpay_icon_info")
    }()

    private lazy var infoURL: URL? = {
        let language = locale.stp_languageCode?.lowercased() ?? "en"
        let region = locale.stp_regionCode?.uppercased() ?? "US"
        let localeCode = "\(language)_\(region)"
        return URL(string: "https://static.afterpay.com/modal/\(localeCode).html")
    }()

    let locale: Locale

    init(locale: Locale = Locale.autoupdatingCurrent, theme: ElementsAppearance = .default) {
        self.locale = locale
        self.theme = theme
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
        let stringAttributes = [
            NSAttributedString.Key.font: theme.fonts.subheadline,
            .foregroundColor: theme.colors.bodyText,
        ]
        let template = STPLocalizedString(
            "Buy now or pay later with <img/>",
            "Promotional text for Afterpay/Clearpay - the image tag will display the Afterpay or Clearpay logo. This text is displayed in a button that lets the customer pay with Afterpay/Clearpay"
        )

        let resultingString = NSMutableAttributedString()
        resultingString.append(NSAttributedString(string: ""))
        guard let img = template.range(of: "<img/>") else {
            return resultingString
        }

        var imgAppended = false

        for (indexOffset, currCharacter) in template.enumerated() {
            let currIndex = template.index(template.startIndex, offsetBy: indexOffset)
            if img.contains(currIndex) {
                if imgAppended {
                    continue
                }
                imgAppended = true
                let titleFont = stringAttributes[NSAttributedString.Key.font] as! UIFont
                let clearPay = attributedStringOfImageWithoutLink(uiImage: afterpayMarkImage, font: titleFont)
                let infoButton = attributedStringOfImageWithoutLink(uiImage: infoImage, font: titleFont)
                resultingString.append(clearPay)
                resultingString.append(NSAttributedString(string: "\u{00A0}\u{00A0}", attributes: stringAttributes))
                resultingString.append(infoButton)
            } else {
                resultingString.append(NSAttributedString(string: String(currCharacter),
                                                          attributes: stringAttributes))
            }
        }
        return resultingString
    }

    private func attributedStringOfImageWithoutLink(uiImage: UIImage, font: UIFont) -> NSAttributedString {
        let imageAttachment = NSTextAttachment()
        imageAttachment.bounds = boundsOfImage(font: font, uiImage: uiImage)
        imageAttachment.image = uiImage
        return NSAttributedString(attachment: imageAttachment)
    }

    // https://stackoverflow.com/questions/26105803/center-nstextattachment-image-next-to-single-line-uilabel
    private func boundsOfImage(font: UIFont, uiImage: UIImage) -> CGRect {
        return CGRect(x: 0,
                      y: (font.capHeight - uiImage.size.height).rounded() / 2,
                      width: uiImage.size.width,
                      height: uiImage.size.height)
    }

    @objc
    private func didTapInfoButton() {
        if let url = infoURL {
            let safariController = SFSafariViewController(url: url)
            safariController.modalPresentationStyle = .overCurrentContext
            parentViewController?.present(safariController, animated: true)
        }
    }

#if !canImport(CompositorServices)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        afterpayMarkImageView.tintColor = theme.colors.parentBackground.contrastingColor
    }
#endif

    static func shouldUseClearpayBrand(for locale: Locale) -> Bool {
        // See https://github.com/search?q=repo%3Aafterpay%2Fsdk-ios%20clearpay&type=code for latest rules
        switch (locale.stp_languageCode, locale.stp_regionCode) {
        case ("en", "GB"):
            return true
        default:
            return false
        }
    }
}

private extension UIResponder {
    var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}
