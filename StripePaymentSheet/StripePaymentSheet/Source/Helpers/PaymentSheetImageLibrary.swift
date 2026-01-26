//
//  PaymentSheetImageLibrary.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

class PaymentSheetImageLibrary {

    /// An icon representing Afterpay.
    class func afterpayLogo(currency: String? = nil) -> UIImage {
        if AfterpayPriceBreakdownView.shouldUseClearpayBrand(for: currency) {
            return self.safeImageNamed("clearpay_mark", templateIfAvailable: true)
        } else if AfterpayPriceBreakdownView.shouldUseCashAppBrand(for: currency) {
            return self.safeImageNamed("cash_app_afterpay_mark", templateIfAvailable: true)
        } else {
            return self.safeImageNamed("afterpay_mark", templateIfAvailable: true)
        }
    }

    /// This returns the appropriate icon for the affirm logo
    class func affirmLogo() -> UIImage {
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

    class func bankIcon(for bank: String?, iconStyle: PaymentSheet.Appearance.IconStyle) -> UIImage {
        guard let bank = bank else {
            return STPPaymentMethodType.USBankAccount.makeImage(iconStyle: iconStyle) ?? UIImage()
        }
        let icon = safeImageNamed("bank_icon_\(bank.lowercased())")
        if icon.size == .zero {
            return STPPaymentMethodType.USBankAccount.makeImage(iconStyle: iconStyle) ?? UIImage() // use generic
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
        return Image.link_bank_icon.makeImage(template: true)
    }

    // MARK: - Card Brand Images

    /// This returns the appropriate icon for the specified card brand.
    class func cardBrandImage(for brand: STPCardBrand) -> UIImage {
        let imageName: String
        switch brand {
        case .amex:
            imageName = "ps_card_amex"
        case .dinersClub:
            imageName = "ps_card_diners"
        case .discover:
            imageName = "ps_card_discover"
        case .JCB:
            imageName = "ps_card_jcb"
        case .mastercard:
            imageName = "ps_card_mastercard"
        case .unionPay:
            imageName = "ps_card_unionpay"
        case .cartesBancaires:
            imageName = "ps_card_cartes_bancaires"
        case .visa:
            imageName = "ps_card_visa"
        case .unknown:
            imageName = "ps_card_unknown"
        @unknown default:
            imageName = "ps_card_unknown"
        }
        return safeImageNamed(imageName)
    }

    /// This returns an unpadded image for the specified card brand if available.
    class func unpaddedCardBrandImage(for brand: STPCardBrand) -> UIImage {
        switch brand {
        case .cartesBancaires:
            return safeImageNamed("ps_card_unpadded_cartes_bancaires")
        case .visa:
            return safeImageNamed("ps_card_unpadded_visa")
        case .amex:
            return safeImageNamed("ps_card_unpadded_amex")
        case .mastercard:
            return safeImageNamed("ps_card_unpadded_mastercard")
        case .dinersClub:
            return safeImageNamed("ps_card_unpadded_diners_club")
        case .unionPay:
            return safeImageNamed("ps_card_unpadded_unionpay")
        case .discover:
            return safeImageNamed("ps_card_unpadded_discover")
        case .JCB:
            return safeImageNamed("ps_card_unpadded_jcb")
        case .unknown:
            return cardBrandImage(for: brand)
        @unknown default:
            return cardBrandImage(for: brand)
        }
    }

    /// This returns a small icon indicating the CVC location for the given card brand.
    class func cvcImage(for brand: STPCardBrand) -> UIImage {
        let imageName = brand == .amex ? "ps_card_cvc_amex" : "ps_card_cvc"
        return safeImageNamed(imageName)
    }

    /// An icon to use when the type of the card is unknown.
    class func unknownCardCardImage() -> UIImage {
        return cardBrandImage(for: .unknown)
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
extension PaymentSheetImageLibrary: ImageMaker {
    typealias BundleLocator = StripePaymentSheetBundleLocator
}
