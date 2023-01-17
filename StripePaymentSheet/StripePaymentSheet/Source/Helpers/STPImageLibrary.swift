//
//  STPImageLibrary.swift
//  StripePaymentSheet
//
//  Created by David Estes on 7/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class PaymentSheetImageLibrary {

    /// An icon representing Afterpay.
    @objc
    public class func afterpayLogo(locale: Locale = Locale.current) -> UIImage {
        switch (locale.languageCode, locale.regionCode) {
        case ("en", "GB"):
            return self.safeImageNamed("clearpay_mark", templateIfAvailable: true)
        default:
            return self.safeImageNamed("afterpay_mark", templateIfAvailable: true)
        }
    }

    /// This returns the appropriate icon for the affirm logo
    @objc
    public class func affirmLogo() -> UIImage {
        if isDarkMode(){
            return Image.affirm_copy_dark.makeImage()
        }
        return Image.affirm_copy.makeImage()
    }

    static let BankIconCodeRegexes: [String: [String]] = [
        "boa": [#"Bank of America"#],
        "capitalone": [#"Capital One"#],
        "citibank": [#"Citibank"#],
        "compass": [#"BBVA"#, #"COMPASS"#],
        "morganchase": [#"MORGAN CHASE"#, #"JP MORGAN"#, #"Chase"#],
        "nfcu": [#"NAVY FEDERAL CREDIT UNION"#],
        "pnc": [#"PNC\s?BANK"#, #"PNC Bank"#],
        "stripe": [#"Stripe"#, #"Test Institution"#],
        "suntrust": [#"SUNTRUST"#, #"SunTrust Bank"#],
        "svb": [#"Silicon Valley Bank"#],
        "td": [#"TD Bank"#],
        "usaa": [#"USAA FEDERAL SAVINGS BANK"#, #"USAA Bank"#],
        "usbank": [#"U\.?S\.? BANK"#, #"US Bank"#],
        "wellsfargo": [#"Wells Fargo"#],
    ]

    class func bankIconCode(for bankName: String?) -> String {
        guard let bankName = bankName else {
            return "default"
        }
        for (iconCode, regexes) in BankIconCodeRegexes {
            for pattern in regexes {
                if bankName.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                    return iconCode
                }
            }
        }
        return "default"
    }

    class func bankIcon(for bank: String?) -> UIImage {
        guard let bank = bank else {
            return STPImageLibrary.bankIcon()
        }
        let icon = safeImageNamed("bank_icon_\(bank.lowercased())")
        if icon.size == .zero {
            return STPImageLibrary.bankIcon() // use generic
        }
        return icon
    }
}

// MARK: - v2 Images

extension STPCardBrand {
    /// Returns a borderless image of the card brand's logo
    func makeCarouselImage() -> UIImage {
        let imageName: String
        switch self {
        case .JCB:
            imageName = "card_jcb"
        case .visa:
            imageName = "card_visa"
        case .amex:
            imageName = "card_amex"
        case .mastercard:
            imageName = "card_mastercard"
        case .discover:
            imageName = "card_discover"
        case .dinersClub:
            imageName = "card_diners"
        case .unionPay:
            imageName = "card_unionpay"
        case .unknown:
            imageName = "card_unknown"
        @unknown default:
            imageName = "card_unknown"
        }
        let brandImage = STPImageLibrary.safeImageNamed(imageName, templateIfAvailable: false)
        // Don't allow tint colors to change the brand images.
        return brandImage.withRenderingMode(.alwaysOriginal)
    }
}

// MARK: - ImageMaker

// :nodoc:
@_spi(STP) extension PaymentSheetImageLibrary: ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripePaymentSheetBundleLocator
}
