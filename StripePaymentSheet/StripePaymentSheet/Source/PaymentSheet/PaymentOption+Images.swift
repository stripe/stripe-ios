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
        currency: String?,
        updateImageHandler: DownloadManager.UpdateImageHandler?
    ) -> UIImage {
        switch self {
        case .applePay:
            return Image.apple_pay_mark.makeImage().withRenderingMode(.alwaysOriginal)
        case .saved(let paymentMethod, let paymentOption):
            if let linkedBank = paymentOption?.instantDebitsLinkedBank {
                return PaymentSheetImageLibrary.bankIcon(for: PaymentSheetImageLibrary.bankIconCode(for: linkedBank.bankName))
            } else {
                return paymentMethod.makeIcon()
            }
        case .new(let confirmParams):
            return confirmParams.makeIcon(currency: currency, updateImageHandler: updateImageHandler)
        case .link(let linkConfirmOption):
            switch linkConfirmOption {
            case .signUp(_, _, _, _, let confirmParams):
                return confirmParams.makeIcon(currency: currency, updateImageHandler: updateImageHandler)
            case .wallet, .withPaymentMethod, .withPaymentDetails:
                return Image.link_logo.makeImage()
            }
        case .external(let paymentMethod, _):
            return PaymentSheet.PaymentMethodType.external(paymentMethod).makeImage(
                forDarkBackground: traitCollection?.isDarkMode ?? false,
                currency: currency,
                updateHandler: nil
            )
        }
    }

    /// Returns an image to display inside a cell representing the given payment option in the saved PM collection view
    func makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: UIUserInterfaceStyle) -> UIImage {
        switch self {
        case .applePay:
            return Image.carousel_applepay.makeImage(template: false, overrideUserInterfaceStyle: overrideUserInterfaceStyle)
        case .saved(let paymentMethod, _):
            return paymentMethod.makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
        case .new:
            assertionFailure("This shouldn't be called - we don't show new PMs in the saved PM collection view")
            return UIImage()
        case .link:
            return Image.link_logo.makeImage()
        case .external:
            assertionFailure("This shouldn't be called - we don't show EPMs in the saved PM collection view")
            return UIImage()
        }
    }
}

extension STPPaymentMethod {
    /// Returns the first non-unknown card brand, prioritizing the card's preferred network brand > display brand > brand
    func calculateCardBrandToDisplay() -> STPCardBrand {
        guard let card else { return .unknown }
        let preferredDisplayBrand = card.networks?.preferred?.toCardBrand
        let displayBrand = card.displayBrand?.toCardBrand
        return [preferredDisplayBrand, displayBrand, card.brand].compactMap { $0 }.first {
            $0 != .unknown
        } ?? .unknown
    }

    func makeIcon() -> UIImage {
        switch type {
        case .card:
            return STPImageLibrary.cardBrandImage(for: calculateCardBrandToDisplay())
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
    func makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: UIUserInterfaceStyle?) -> UIImage {
        switch type {
        case .card:
            return calculateCardBrandToDisplay().makeSavedPaymentMethodCellImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle)
        case .USBankAccount:
            return PaymentSheetImageLibrary.bankIcon(
                for: PaymentSheetImageLibrary.bankIconCode(for: usBankAccount?.bankName)
            )
        case .SEPADebit:
            return Image.carousel_sepa.makeImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle).withRenderingMode(.alwaysOriginal)
        case .link:
            return Image.link_logo.makeImage(overrideUserInterfaceStyle: overrideUserInterfaceStyle).withRenderingMode(.alwaysOriginal)
        default:
            assertionFailure("\(type) not supported for saved PMs")
            return makeIcon()
        }
    }

    /// Returns an image to display inside a row representing the given payment option in the saved PM row view
    func makeSavedPaymentMethodRowImage() -> UIImage {
        switch type {
        case .card:
            return STPImageLibrary.unpaddedCardBrandImage(for: calculateCardBrandToDisplay())
        case .USBankAccount:
            return PaymentSheetImageLibrary.bankIcon(
                for: PaymentSheetImageLibrary.bankIconCode(for: usBankAccount?.bankName)
            ).rounded(radius: 3)
        case .SEPADebit:
            return Image.pm_type_sepa.makeImage().withRenderingMode(.alwaysOriginal)
        default:
            assertionFailure("\(type) not supported for saved PMs")
            return makeIcon()
        }
    }
}

 extension STPPaymentMethodParams {
    func makeIcon(currency: String?, updateHandler: DownloadManager.UpdateImageHandler?) -> UIImage {
        switch type {
        case .card:
            let brand = STPCardValidator.brand(for: card)
            return STPImageLibrary.cardBrandImage(for: brand)
        default:
            // If there's no image specific to this PaymentMethod (eg card network logo, bank logo), default to the PaymentMethod type's icon
            // TODO: Refactor this out of PaymentMethodType. Users shouldn't have to convert STPPaymentMethodType to PaymentMethodType in order to get its image.
            return PaymentSheet.PaymentMethodType.stripe(type).makeImage(currency: currency, updateHandler: updateHandler)
        }
    }
 }

extension STPPaymentMethodType {

    /// A few payment method type icons need to be tinted white or black as they do not have
    /// light/dark agnostic icons
    var iconRequiresTinting: Bool {
        switch self {
        case .card, .AUBECSDebit, .USBankAccount, .konbini, .boleto, .bacsDebit:
            return true
        default:
            return false
        }
    }

    func makeImage(forDarkBackground: Bool = false, currency: String? = nil) -> UIImage? {
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
                return AfterpayPriceBreakdownView.shouldUseCashAppBrand(for: currency) ? .pm_type_cashapp : .pm_type_afterpay
            case .sofort, .klarna:
                return .pm_type_klarna
            case .affirm:
                return .pm_type_affirm
            case .payPal:
                return .pm_type_paypal
            case .AUBECSDebit:
                return .pm_type_aubecsdebit
            case .USBankAccount:
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

extension STPPaymentMethodCard {
    var preferredDisplayBrand: STPCardBrand {
        return networks?.preferred?.toCardBrand ?? displayBrand?.toCardBrand ?? brand
    }
}

extension UIImage {
    func rounded(radius: CGFloat) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
