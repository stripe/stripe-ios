//
//  PaymentOption+Images.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension PaymentOption {
    /// Returns an icon representing the payment option, suitable for display on a checkout screen
    func makeIcon(for traitCollection: UITraitCollection? = nil) -> UIImage {
        switch self {
        case .applePay:
            return Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal)
        case .saved(let paymentMethod):
            return paymentMethod.makeIcon(for: traitCollection)
        case .new(let confirmParams):
            return confirmParams.paymentMethodParams.makeIcon(for: traitCollection)
        case .link(_, let confirmOption):
            switch confirmOption {
            case .forNewAccount(_, let paymentMethodParams):
                return paymentMethodParams.makeIcon(for: traitCollection)
            case .withPaymentDetails(let paymentDetails):
                return paymentDetails.makeIcon()
            case .withPaymentMethodParams(let paymentMethodParams):
                return paymentMethodParams.makeIcon(for: traitCollection)
            }
        }
    }

    /// Returns an image representing the payment option, suitable for display within PaymentSheet cells
    func makeCarouselImage(for view: UIView) -> UIImage {
        switch self {
        case .applePay:
            return makeIcon(for: view.traitCollection)
        case .saved(let paymentMethod):
            return paymentMethod.makeCarouselImage(for: view)
        case .new(let confirmParams):
            return confirmParams.paymentMethodParams.makeCarouselImage(for: view)
        case .link:
            assertionFailure("Link is not offered in PaymentSheet carousel")
            return UIImage()
        }
    }
}

extension STPPaymentMethod {
    func makeIcon(for traitCollection: UITraitCollection? = nil) -> UIImage {
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
            return type.makeImage(for: traitCollection)
        }
    }

    func makeCarouselImage(for view: UIView) -> UIImage {
        if type == .card, let cardBrand = card?.brand {
            return cardBrand.makeCarouselImage()
        }
        return makeIcon(for: view.traitCollection)
    }
}

extension STPPaymentMethodParams {
    func makeIcon(for traitCollection: UITraitCollection? = nil) -> UIImage {
        switch type {
        case .card:
            guard let card = card, let number = card.number else {
                return STPImageLibrary.unknownCardCardImage()
            }

            let brand = STPCardValidator.brand(forNumber: number)
            return STPImageLibrary.cardBrandImage(for: brand)
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            return type.makeImage(for: traitCollection)
        }
    }

    func makeCarouselImage(for view: UIView) -> UIImage {
        if type == .card, let card = card, let number = card.number {
            let cardBrand = STPCardValidator.brand(forNumber: number)
            return cardBrand.makeCarouselImage()
        }
        return makeIcon(for: view.traitCollection)
    }
}

extension ConsumerPaymentDetails {
    func makeIcon() -> UIImage {
        switch details {
            
        case .card(let card):
            return STPImageLibrary.cardBrandImage(for: card.brand)
        case .bankAccount(let bankAccount):
            return STPImageLibrary.bankIcon(for: bankAccount.iconCode)
        }
    }
}

extension STPPaymentMethodType {
    func makeImage(for traitCollection: UITraitCollection? = nil) -> UIImage {
        guard let image: Image = {
            switch self {
            case .card:
                return .pm_type_card
            case .iDEAL:
                return .pm_type_ideal
            case .bancontact:
                return .pm_type_bancontact
            case .SEPADebit:
                return .pm_type_sepa
            case .EPS:
                return .pm_type_eps
            case .giropay:
                return .pm_type_giropay
            case .przelewy24:
                return .pm_type_p24
            case .afterpayClearpay:
                return .pm_type_afterpay
            case .sofort, .klarna:
                return .pm_type_klarna
            case .affirm:
                return .pm_type_affirm
            case .payPal:
                return .pm_type_paypal
            case .AUBECSDebit:
                return .pm_type_aubecsdebit
            case .linkInstantDebit:
                return .pm_type_link_instant_debit
            default:
                return nil
            }
        }() else {
            assertionFailure()
            return UIImage()
        }
        // Tint the image white for darkmode
        if traitCollection?.isDarkMode ?? isDarkMode(),
           let imageTintedWhite = image.makeImage(template: true)
            .compatible_withTintColor(.white)?
            .withRenderingMode(.alwaysOriginal) {
            return imageTintedWhite
        } else {
            return image.makeImage(darkMode: false)
        }
    }
}
