//
//  PaymentOption+Images.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension PaymentOption {
    /// Returns an icon representing the payment option, suitable for display on a checkout screen
    func makeIcon(
        for traitCollection: UITraitCollection? = nil,
        updateImageHandler: DownloadManager.UpdateImageHandler?
    ) -> UIImage {
        switch self {
        case .applePay:
            return Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal)
        case .saved(let paymentMethod):
            return paymentMethod.makeIcon()
        case .new(let confirmParams):
            return confirmParams.makeIcon(updateImageHandler: updateImageHandler)
        case .link:
            return Image.pm_type_link.makeImage()
        case .externalPayPal:
            return Image.pm_type_paypal.makeImage()
        }
    }

    /// Returns an image representing the payment option, suitable for display within PaymentSheet cells
    func makeCarouselImage(for view: UIView) -> UIImage {
        switch self {
        case .applePay:
            return makeIcon(for: view.traitCollection, updateImageHandler: nil)
        case .saved(let paymentMethod):
            return paymentMethod.makeCarouselImage(for: view)
        case .new(let confirmParams):
            return confirmParams.paymentMethodParams.makeCarouselImage(for: view)
        case .link:
            return Image.link_carousel_logo.makeImage(template: true)
        case .externalPayPal:
            return Image.pm_type_paypal.makeImage()
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
        case .USBankAccount:
            return PaymentSheetImageLibrary.bankIcon(
                for: PaymentSheetImageLibrary.bankIconCode(for: usBankAccount?.bankName)
            )
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            return type.makeImage()
        }
    }

    func makeCarouselImage(for view: UIView) -> UIImage {
        if type == .card, let cardBrand = card?.brand {
            return cardBrand.makeCarouselImage()
        } else if type == .USBankAccount {
            return PaymentSheetImageLibrary.bankIcon(
                for: PaymentSheetImageLibrary.bankIconCode(for: usBankAccount?.bankName)
            )
        }
        return makeIcon()
    }
}

extension STPPaymentMethodParams {
    func makeIcon(updateHandler: DownloadManager.UpdateImageHandler?) -> UIImage {
        switch type {
        case .card:
            guard let card = card, let number = card.number else {
                return STPImageLibrary.unknownCardCardImage()
            }

            let brand = STPCardValidator.brand(forNumber: number)
            return STPImageLibrary.cardBrandImage(for: brand)
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            return self.paymentSheetPaymentMethodType().makeImage(updateHandler: updateHandler)
        }
    }

    func makeCarouselImage(for view: UIView) -> UIImage {
        if type == .card, let card = card, let number = card.number {
            let cardBrand = STPCardValidator.brand(forNumber: number)
            return cardBrand.makeCarouselImage()
        }
        return makeIcon(updateHandler: nil)
    }
}

extension ConsumerPaymentDetails {
    func makeIcon() -> UIImage {
        switch details {
        case .card(let card):
            return STPImageLibrary.cardBrandImage(for: card.stpBrand)
        case .bankAccount(let bankAccount):
            return PaymentSheetImageLibrary.bankIcon(for: bankAccount.iconCode)
        case .unparsable:
            return UIImage()
        }
    }
}

extension STPPaymentMethodType {

    /// A few payment method type icons need to be tinted white or black as they do not have
    /// light/dark agnostic icons
    var iconRequiresTinting: Bool {
        return self == .card || self == .AUBECSDebit || self == .USBankAccount || self == .linkInstantDebit
    }

    func makeImage(forDarkBackground: Bool = false) -> UIImage {
        guard
            let image: Image = {
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
                case .USBankAccount, .linkInstantDebit:
                    return .pm_type_us_bank
                case .UPI:
                    return .pm_type_upi
                case .cashApp:
                    return .pm_type_cashapp
                case .blik:
                    return .pm_type_blik
                default:
                    return nil
                }
            }()
        else {
            assertionFailure()
            return UIImage()
        }

        // payment method type icons are light/dark agnostic except PayPal
        return image.makeImage(darkMode: self == .payPal ? forDarkBackground : false)
    }
}
