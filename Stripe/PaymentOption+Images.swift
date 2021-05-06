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
            return STPImageLibrary.safeImageNamed("apple_pay_mark", templateIfAvailable: false)
                .withRenderingMode(.alwaysOriginal)
        case .saved(let paymentMethod):
            return paymentMethod.makeIcon()
        case .new(let paymentMethodParams, _):
            return paymentMethodParams.makeIcon()
        }
    }

    /// Returns an image representing the payment option, suitable for display within PaymentSheet cells
    func makeCarouselImage() -> UIImage {
        switch self {
        case .applePay:
            return makeIcon()
        case .saved(let paymentMethod):
            return paymentMethod.makeCarouselImage()
        case .new(let paymentMethodParams, _):
            return paymentMethodParams.makeCarouselImage()
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
            return STPImageLibrary.safeImageNamed("icon-pm-ideal")
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
        let imageName: String
        switch self {
        case .card:
            imageName = "icon-pm-card"
        case .iDEAL:
            imageName = "icon-pm-ideal"
        default:
            assertionFailure()
            imageName = ""
        }
        // Tint the image white for darkmode
        if isDarkMode(),
           let imageTintedWhite = STPImageLibrary
            .safeImageNamed(imageName, templateIfAvailable: true)
            .compatible_withTintColor(.white)?
            .withRenderingMode(.alwaysOriginal) {
            return imageTintedWhite
        } else {
            return STPImageLibrary.safeImageNamed(imageName)
        }
    }
}
