//
//  STPImageLibrary.swift
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

//
//  STPImages.m
//  Stripe
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

@_spi(STP) import StripeUICore

/// This class lets you access card icons used by the Stripe SDK. All icons are 32 x 20 points.
public class STPImageLibrary: NSObject {
    /// An icon representing Apple Pay.
    @objc
    public class func applePayCardImage() -> UIImage {
        return self.safeImageNamed("stp_card_applepay")
    }

    /// An icon representing American Express.
    @objc
    public class func amexCardImage() -> UIImage {
        return self.cardBrandImage(for: .amex)
    }

    /// An icon representing Diners Club.
    @objc
    public class func dinersClubCardImage() -> UIImage {
        return self.cardBrandImage(for: .dinersClub)
    }

    /// An icon representing Discover.
    @objc
    public class func discoverCardImage() -> UIImage {
        return self.cardBrandImage(for: .discover)
    }

    /// An icon representing JCB.
    @objc
    public class func jcbCardImage() -> UIImage {
        return self.cardBrandImage(for: .JCB)
    }

    /// An icon representing Mastercard.
    @objc
    public class func mastercardCardImage() -> UIImage {
        return self.cardBrandImage(for: .mastercard)
    }

    /// An icon representing UnionPay.
    @objc
    public class func unionPayCardImage() -> UIImage {
        return self.cardBrandImage(for: .unionPay)
    }

    /// An icon representing Visa.
    @objc
    public class func visaCardImage() -> UIImage {
        return self.cardBrandImage(for: .visa)
    }

    /// An icon to use when the type of the card is unknown.
    @objc
    public class func unknownCardCardImage() -> UIImage {
        return self.cardBrandImage(for: .unknown)
    }

    /// This returns the appropriate icon for the specified card brand.
    @objc(brandImageForCardBrand:) public class func cardBrandImage(for brand: STPCardBrand)
        -> UIImage
    {
        return self.brandImage(for: brand, template: false)
    }

    /// This returns the appropriate icon for the specified bank brand.
    @objc(brandImageForFPXBankBrand:) public class func fpxBrandImage(for brand: STPFPXBankBrand)
        -> UIImage
    {
        let imageName = "stp_bank_fpx_\(STPFPXBank.identifierFrom(brand) ?? "")"
        let image = self.safeImageNamed(
            imageName,
            templateIfAvailable: false)
        return image
    }

    /// An icon representing FPX.
    @objc
    public class func fpxLogo() -> UIImage {
        return self.safeImageNamed("stp_fpx_logo", templateIfAvailable: false)
    }

    /// A large branding image for FPX.
    @objc
    public class func largeFpxLogo() -> UIImage {
        return self.safeImageNamed("stp_fpx_big_logo", templateIfAvailable: false)
    }

    /// An icon representing Afterpay.
    @objc
    public class func afterpayLogo(locale: Locale = Locale.current) -> UIImage {
        switch (locale.regionCode) {
        case "GB", "FR", "ES", "IT":
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
    
    /// This returns the appropriate icon for the specified card brand as a
    /// single color template that can be tinted
    @objc(templatedBrandImageForCardBrand:) public class func templatedBrandImage(
        for brand: STPCardBrand
    ) -> UIImage {
        return self.brandImage(for: brand, template: true)
    }

    /// This returns a small icon indicating the CVC location for the given card brand.
    @objc(cvcImageForCardBrand:) public class func cvcImage(for brand: STPCardBrand) -> UIImage {
        let imageName = brand == .amex ? "stp_card_cvc_amex" : "stp_card_cvc"
        return self.safeImageNamed(imageName)
    }

    /// This returns a small icon indicating a card number error for the given card brand.
    @objc(errorImageForCardBrand:) public class func errorImage(for brand: STPCardBrand) -> UIImage
    {
        let imageName = brand == .amex ? "stp_card_error_amex" : "stp_card_error"
        return self.safeImageNamed(imageName)
    }

    @objc class func addIcon() -> UIImage {
        return self.safeImageNamed("stp_icon_add", templateIfAvailable: true)
    }

    @objc class func bankIcon() -> UIImage {
        return self.safeImageNamed("stp_icon_bank", templateIfAvailable: true)
    }

    @objc class func checkmarkIcon() -> UIImage {
        return self.safeImageNamed("stp_icon_checkmark", templateIfAvailable: true)
    }

    @objc class func largeCardFrontImage() -> UIImage {
        return self.safeImageNamed("stp_card_form_front", templateIfAvailable: true)
    }

    @objc class func largeCardBackImage() -> UIImage {
        return self.safeImageNamed("stp_card_form_back", templateIfAvailable: true)
    }

    @objc class func largeCardAmexCVCImage() -> UIImage {
        return self.safeImageNamed("stp_card_form_amex_cvc", templateIfAvailable: true)
    }

    @objc class func largeShippingImage() -> UIImage {
        return self.safeImageNamed("stp_shipping_form", templateIfAvailable: true)
    }

    // TODO: This method can be removed when STPImageLibraryTest is converted to Swift
    @objc(safeImageNamed:templateIfAvailable:)
    class func _objc_safeImageNamed(
        _ imageName: String,
        templateIfAvailable: Bool
    ) -> UIImage {
        safeImageNamed(imageName, templateIfAvailable: templateIfAvailable)
    }

    class func brandImage(
        for brand: STPCardBrand,
        template isTemplate: Bool
    ) -> UIImage {
        var shouldUseTemplate = isTemplate
        var imageName: String?
        switch brand {
        case .amex:
            imageName = shouldUseTemplate ? "stp_card_amex_template" : "stp_card_amex"
        case .dinersClub:
            imageName = shouldUseTemplate ? "stp_card_diners_template" : "stp_card_diners"
        case .discover:
            imageName = shouldUseTemplate ? "stp_card_discover_template" : "stp_card_discover"
        case .JCB:
            imageName = shouldUseTemplate ? "stp_card_jcb_template" : "stp_card_jcb"
        case .mastercard:
            imageName = shouldUseTemplate ? "stp_card_mastercard_template" : "stp_card_mastercard"
        case .unionPay:
            if Locale.current.identifier.lowercased().hasPrefix("zh") {
                imageName =
                    shouldUseTemplate ? "stp_card_unionpay_template_zh" : "stp_card_unionpay_zh"
            } else {
                imageName =
                    shouldUseTemplate ? "stp_card_unionpay_template_en" : "stp_card_unionpay_en"
            }
        case .unknown:
            shouldUseTemplate = true
            imageName = "stp_card_unknown"
        case .visa:
            imageName = shouldUseTemplate ? "stp_card_visa_template" : "stp_card_visa"
        @unknown default:
            shouldUseTemplate = true
            imageName = "stp_card_unknown"
        }
        let image = self.safeImageNamed(
            imageName ?? "",
            templateIfAvailable: shouldUseTemplate)
        return image
    }

    class func image(
        withTintColor color: UIColor,
        for image: UIImage
    ) -> UIImage {
        var newImage: UIImage?
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        color.set()
        let templateImage = image.withRenderingMode(.alwaysTemplate)
        templateImage.draw(
            in: CGRect(
                x: 0, y: 0, width: templateImage.size.width, height: templateImage.size.height))
        newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
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
    ];

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
            return bankIcon()
        }
        let icon = safeImageNamed("bank_icon_\(bank.lowercased())")
        if icon.size == .zero {
            return bankIcon() // use generic
        }
        return icon
    }
}

// MARK: - ImageMaker

/// :nodoc:
@_spi(STP) extension STPImageLibrary: ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripeBundleLocator
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
        }
        let brandImage = STPImageLibrary.safeImageNamed(imageName, templateIfAvailable: false)
        // Don't allow tint colors to change the brand images.
        return brandImage.withRenderingMode(.alwaysOriginal)
    }
}
