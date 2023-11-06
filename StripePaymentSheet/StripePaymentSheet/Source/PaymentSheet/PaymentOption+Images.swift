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

    /// Returns an image to display inside a cell representing the given payment option in the saved PM collection view
    func makeSavedPaymentMethodCellImage(for view: UIView) -> UIImage {
        switch self {
        case .applePay:
            return Image.carousel_applepay.makeImage(template: false)
        case .saved(let paymentMethod):
            return paymentMethod.makeSavedPaymentMethodCellImage()
        case .new:
            assertionFailure("This shouldn't be called - we don't show new PMs in the saved PM collection view")
            return UIImage()
        case .link:
            return Image.carousel_link.makeImage(template: false)
        case .externalPayPal:
            assertionFailure("This shouldn't be called - we don't show EPMs in the saved PM collection view")
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

            return STPImageLibrary.cardBrandImage(for: card.networks?.preferred?.toCardBrand ?? card.brand)
        case .USBankAccount:
            return PaymentSheetImageLibrary.bankIcon(
                for: PaymentSheetImageLibrary.bankIconCode(for: usBankAccount?.bankName)
            )
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            // TODO: This only looks at client-side assets! 
            let image = type.makeImage()
            if image == nil {
                assertionFailure()
            }
            return image ?? UIImage()
        }
    }

    /// Returns an image to display inside a cell representing the given payment option in the saved PM collection view
    func makeSavedPaymentMethodCellImage() -> UIImage {
        switch type {
        case .card:
            let cardBrand = card?.networks?.preferred?.toCardBrand ?? card?.brand ?? .unknown
            return cardBrand.makeSavedPaymentMethodCellImage()
        case .USBankAccount:
            return PaymentSheetImageLibrary.bankIcon(
                for: PaymentSheetImageLibrary.bankIconCode(for: usBankAccount?.bankName)
            )
        case .SEPADebit:
            return Image.carousel_sepa.makeImage().withRenderingMode(.alwaysOriginal)
        case .link:
            return Image.carousel_link.makeImage().withRenderingMode(.alwaysOriginal)
        default:
            assertionFailure("\(type) not supported for saved PMs")
            return makeIcon()
        }
    }
}

extension STPPaymentMethodParams {
    func makeIcon(updateHandler: DownloadManager.UpdateImageHandler?) -> UIImage {
        switch type {
        case .card:
            guard let card = card, let number = card.number else {
                return STPImageLibrary.unknownCardCardImage()
            }

            let brand = card.networks?.preferred?.toCardBrand ?? STPCardValidator.brand(forNumber: number)
            return STPImageLibrary.cardBrandImage(for: brand)
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            // TODO: Refactor this out of PaymentMethodType. Users shouldn't have to convert STPPaymentMethodType to PaymentMethodType in order to get its image.
            return PaymentSheet.PaymentMethodType.stripe(type).makeImage(updateHandler: updateHandler)
        }
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
        switch self {
        case .card, .AUBECSDebit, .USBankAccount, .linkInstantDebit, .konbini, .boleto:
            return true
        default:
            return false
        }
    }

    func makeImage(forDarkBackground: Bool = false) -> UIImage? {
        let image: Image? = {
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
            case .revolutPay:
                return .pm_type_revolutpay
            case .blik:
                return .pm_type_blik
            case .bacsDebit:
                return .pm_type_us_bank
            case .alipay:
                return .pm_type_alipay
            case .OXXO:
                return .pm_type_oxxo
            case .konbini:
                return .pm_type_konbini
            case .boleto:
                return .pm_type_boleto
            case .swish:
                return .pm_type_swish
            default:
                return nil
            }
        }()
        return image?.makeImage(overrideUserInterfaceStyle: forDarkBackground ? .dark : .light)
    }
}

extension String {
    var toCardBrand: STPCardBrand? {
        return STPCard.brand(from: self)
    }
}
