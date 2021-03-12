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

    @objc class func safeImageNamed(_ imageName: String) -> UIImage {
        return self.safeImageNamed(imageName, templateIfAvailable: false)
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

    @objc class func safeImageNamed(
        _ imageName: String,
        templateIfAvailable: Bool
    ) -> UIImage {

        var image = UIImage(
            named: imageName, in: STPBundleLocator.stripeResourcesBundle, compatibleWith: nil)

        if image == nil {
            image = UIImage(named: imageName)
        }
        if templateIfAvailable {
            image = image?.withRenderingMode(.alwaysTemplate)
        }
        assert(image != nil, "Failed to find an image named \(imageName)")

        // Look for a dark variant if available
        // Warning: Accessing the `imageAsset` property mutates the UIImage.
        // Accessing it on a @3x image without subsequently registering a trait collection
        // with the appropriate scale will cause the image to appear at an inappropriate
        // size on non-3x devices. This is why we check for the existence of a dark image
        // *before* accessing `image.imageAsset`.
        if #available(iOS 13.0, *) {
          if let image = image,
             let darkImage = STPImageLibrary.imageNamed(imageName + "_dark", templateIfAvailable: templateIfAvailable),
             let imageAsset = image.imageAsset {
              let lightTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(displayScale: 3.0), // we ship all images as @3x
                UITraitCollection(userInterfaceStyle: .light)
              ])
              let darkTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(displayScale: 3.0),
                UITraitCollection(userInterfaceStyle: .dark)
              ])
              imageAsset.register(image, with: lightTraitCollection)
              imageAsset.register(darkImage, with: darkTraitCollection)
            }
        }
        
        return image ?? UIImage()
    }

    class func imageNamed(
      _ imageName: String,
      templateIfAvailable: Bool
    ) -> UIImage? {

      var image = UIImage(
        named: imageName, in: STPBundleLocator.stripeResourcesBundle, compatibleWith: nil)

      if image == nil {
        image = UIImage(named: imageName)
      }
        
      if templateIfAvailable {
        image = image?.withRenderingMode(.alwaysTemplate)
      }

      return image
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
}

// MARK: - v2 Images
enum Icon: String {
    case checkmark = "icon_checkmark"
    case chevronLeft = "icon_chevron_left"
    case lock = "icon_lock"
    case plus = "icon_plus"
    case x = "icon_x"

    func makeImage() -> UIImage {
        return STPImageLibrary.safeImageNamed(self.rawValue, templateIfAvailable: true)
    }
}

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
