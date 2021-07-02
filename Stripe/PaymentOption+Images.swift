//
//  PaymentOption+Images.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension PaymentOption {
    /// Returns an icon representing the payment option, suitable for display on a checkout screen
    func makeIcon() -> UIImage {
        switch self {
        case .applePay:
            return Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal)
        case .saved(let paymentMethod):
            return paymentMethod.makeIcon()
        case .new(let confirmParams):
            return confirmParams.paymentMethodParams.makeIcon()
        }
    }

    /// Returns an image representing the payment option, suitable for display within PaymentSheet cells
    func makeCarouselImage() -> UIImage {
        switch self {
        case .applePay:
            return makeIcon()
        case .saved(let paymentMethod):
            return paymentMethod.makeCarouselImage()
        case .new(let confirmParams):
            return confirmParams.paymentMethodParams.makeCarouselImage()
        }
    }
}

extension STPPaymentMethod {
    func makeIcon() -> UIImage {
        switch type {
        case .card:
            guard let card = card else {
                return STPImageLibrary.unknownCardCardImage()
            }

            return STPImageLibrary.cardBrandImage(for: card.brand)
        case .iDEAL:
            return Image.pm_type_ideal.makeImage()
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            return type.makeImage()
        }
    }

    func makeCarouselImage() -> UIImage {
        if type == .card, let cardBrand = card?.brand {
            return cardBrand.makeCarouselImage()
        }
        return makeIcon()
    }
}

extension STPPaymentMethodParams {
    func makeIcon() -> UIImage {
        switch type {
        case .card:
            guard let card = card, let number = card.number else {
                return STPImageLibrary.unknownCardCardImage()
            }

            let brand = STPCardValidator.brand(forNumber: number)
            return STPImageLibrary.cardBrandImage(for: brand)
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            return type.makeImage()
        }
    }

    func makeCarouselImage() -> UIImage {
        if type == .card, let card = card, let number = card.number {
            let cardBrand = STPCardValidator.brand(forNumber: number)
            return cardBrand.makeCarouselImage()
        }
        return makeIcon()
    }
}

extension STPPaymentMethodType {
    func makeImage() -> UIImage {
        guard let image: Image = {
            switch self {
            case .card:
                return .pm_type_card
            case .iDEAL:
                return .pm_type_ideal
            case .bancontact:
                return .pm_type_bancontact
            case .sofort:
                return .pm_type_sofort
            case .SEPADebit:
                return .pm_type_sepa
            default:
                return nil
            }
        }() else {
            assertionFailure()
            return UIImage()
        }
        // Tint the image white for darkmode
        if isDarkMode(),
           let imageTintedWhite = image.makeImage(template: true)
            .compatible_withTintColor(.white)?
            .withRenderingMode(.alwaysOriginal) {
            return imageTintedWhite
        } else {
            return image.makeImage()
        }
    }
}
