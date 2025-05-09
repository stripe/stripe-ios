//
//  STPImageLibrary.swift
//  StripePaymentsUI
//
//  Created by Jack Flintermann on 6/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

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
    @objc(brandImageForCardBrand:) public class func cardBrandImage(
        for brand: STPCardBrand
    )
        -> UIImage
    {
        return self.brandImage(for: brand, template: false)
    }

    /// This returns an unpadded image for the specified card brand if available.
    @_spi(STP) public class func unpaddedCardBrandImage(
        for brand: STPCardBrand
    )
        -> UIImage
    {
        switch brand {
        case .cartesBancaires:
            return safeImageNamed("stp_card_unpadded_cartes_bancaires")
        case .visa:
            return safeImageNamed("stp_card_unpadded_visa")
        case .amex:
            return safeImageNamed("stp_card_unpadded_amex")
        case .mastercard:
            return safeImageNamed("stp_card_unpadded_mastercard")
        case .dinersClub:
            return safeImageNamed("stp_card_unpadded_diners_club")
        case .unionPay:
            return safeImageNamed("stp_card_unpadded_unionpay")
        case .discover:
            return safeImageNamed("stp_card_unpadded_discover")
        case .JCB:
            return safeImageNamed("stp_card_unpadded_jcb")
        case .unknown:
            fallthrough
        @unknown default:
            return self.brandImage(for: brand, template: false)
        }
    }

    /// This returns the icon for an unselected brand when multiple card brands are available.
    @objc(cardBrandChoiceImage) public class func cardBrandChoiceImage()
        -> UIImage
    {
        return self.safeImageNamed("stp_card_cbc", templateIfAvailable: false)
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
        return self.safeImageNamed("stp_card_error")
    }

    @_spi(STP) public class func bankIcon() -> UIImage {
        return self.safeImageNamed("stp_icon_bank", templateIfAvailable: true)
    }

    @_spi(STP) public class func linkBankIcon() -> UIImage {
        return self.safeImageNamed("stp_icon_bank_link", templateIfAvailable: true)
    }

    class func brandImage(
        for brand: STPCardBrand,
        template shouldUseTemplate: Bool,
        locale: Locale = .current
    ) -> UIImage {
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
            imageName = shouldUseTemplate ? "stp_card_unionpay_template" : "stp_card_unionpay"
        case .cartesBancaires:
            imageName = shouldUseTemplate ? "stp_card_cartes_bancaires_template" : "stp_card_cartes_bancaires"
        case .unknown:
            imageName = "stp_card_unknown"
        case .visa:
            imageName = shouldUseTemplate ? "stp_card_visa_template" : "stp_card_visa"
        @unknown default:
            imageName = "stp_card_unknown"
        }
        let image = self.safeImageNamed(
            imageName ?? "",
            templateIfAvailable: shouldUseTemplate
        )
        return image
    }
}

// MARK: - ImageMaker

/// :nodoc:
@_spi(STP) extension STPImageLibrary: ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripePaymentsUIBundleLocator
}
