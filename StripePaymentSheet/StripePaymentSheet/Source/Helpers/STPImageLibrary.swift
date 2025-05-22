//
//  STPImageLibrary.swift
//  StripePaymentSheet
//
//  Created by David Estes on 7/6/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class PaymentSheetImageLibrary {

    /// An icon representing Afterpay.
    @objc
    public class func afterpayLogo(currency: String? = nil) -> UIImage {
        if AfterpayPriceBreakdownView.shouldUseClearpayBrand(for: currency) {
            return self.safeImageNamed("clearpay_mark", templateIfAvailable: true)
        } else if AfterpayPriceBreakdownView.shouldUseCashAppBrand(for: currency) {
            return self.safeImageNamed("cash_app_afterpay_mark", templateIfAvailable: true)
        } else {
            return self.safeImageNamed("afterpay_mark", templateIfAvailable: true)
        }
    }

    /// This returns the appropriate icon for the affirm logo
    @objc
    public class func affirmLogo() -> UIImage {
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

    class func bankInstitutionIcon(for bank: String?) -> UIImage? {
        guard let bank else {
            return nil
        }
        let icon = safeImageNamed("bank_icon_\(bank.lowercased())")
        if icon.size == .zero {
            return nil
        }
        return icon
    }

    class func linkBankIcon() -> UIImage {
        STPImageLibrary.linkBankIcon()
    }
}

// MARK: - v2 Images

extension STPCardBrand {
    /// Returns a borderless image of the card brand's logo
    func makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIImage {
        let image: Image
        switch self {
        case .JCB:
            image = .carousel_card_jcb
        case .visa:
            image = .carousel_card_visa
        case .amex:
            image = .carousel_card_amex
        case .mastercard:
            image = .carousel_card_mastercard
        case .discover:
            image = .carousel_card_discover
        case .dinersClub:
            image = .carousel_card_diners
        case .unionPay:
            image = .carousel_card_unionpay
        case .cartesBancaires:
            image = .carousel_card_cartes_bancaires
        case .unknown:
            image = .carousel_card_unknown
        @unknown default:
            image = .carousel_card_unknown
        }
        let brandImage = image.makeImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
        // Don't allow tint colors to change the brand images.
        return brandImage.withRenderingMode(.alwaysOriginal)
    }
}

// MARK: - ImageMaker

// :nodoc:
@_spi(STP) extension PaymentSheetImageLibrary: ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripePaymentSheetBundleLocator
}
