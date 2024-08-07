//
//  STPPaymentMethodParams+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
import UIKit

extension STPPaymentMethodParams: STPPaymentOption {
    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card && card != nil {
            let brand = card?.preferredDisplayBrand ?? .unknown
            return STPImageLibrary.cardBrandImage(for: brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card && card != nil {
            let brand = card?.preferredDisplayBrand ?? .unknown
            return STPImageLibrary.templatedBrandImage(for: brand)
        } else if type == .FPX {
            return STPImageLibrary.bankIcon()
        } else {
            return STPImageLibrary.templatedBrandImage(for: .unknown)
        }
    }

    @objc public var isReusable: Bool {
        switch type {
        case .card, .link, .USBankAccount:
            return true
        case .alipay, .AUBECSDebit, .bacsDebit, .SEPADebit, .iDEAL, .FPX, .cardPresent, .giropay,
            .grabPay, .EPS, .przelewy24, .bancontact, .netBanking, .OXXO, .payPal, .sofort, .UPI,
            .afterpayClearpay, .blik, .weChatPay, .boleto, .klarna, .affirm, .cashApp, .paynow,
            .zip, .revolutPay, .amazonPay, .alma, .mobilePay, .konbini, .promptPay, .swish, .twint,
            .multibanco, .sunbit, .billie, .satispay,
            .unknown:
            return false
        @unknown default:
            return false
        }
    }

    @objc public var label: String {
        switch type {
        case .card:
            if let card = card {
                let brand = STPCardValidator.brand(forNumber: card.number ?? "")
                let brandString = STPCardBrandUtilities.stringFrom(brand)
                return "\(brandString ?? "") \(card.last4 ?? "")"
            } else {
                return STPCardBrandUtilities.stringFrom(.unknown) ?? ""
            }
        case .FPX:
            if let fpx = fpx {
                return STPFPXBank.stringFrom(fpx.bank) ?? ""
            } else {
                return "FPX"
            }
        case .paynow, .zip, .amazonPay, .alma, .mobilePay, .konbini, .promptPay, .swish, .sunbit, .billie, .satispay, .iDEAL, .SEPADebit, .bacsDebit, .AUBECSDebit, .giropay, .przelewy24, .EPS, .bancontact, .netBanking, .OXXO, .sofort, .UPI, .grabPay, .payPal, .afterpayClearpay, .blik, .weChatPay, .boleto, .link, .klarna, .affirm, .USBankAccount, .cashApp, .revolutPay, .twint, .multibanco, .alipay, .cardPresent, .unknown:
            // Use the label already defined in STPPaymentMethodType; the params object for these types don't contain additional information that affect the display label (like cards do)
            return type.displayName
        @unknown default:
            return STPLocalizedString("Unknown", "Default missing source type label")
        }
    }
}

extension STPPaymentMethodCardParams {
    var preferredDisplayBrand: STPCardBrand {
        return networks?.preferred?.toCardBrand ?? STPCardValidator.brand(forNumber: number ?? "")
    }
}
