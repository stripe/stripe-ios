//
//  STPPaymentMethod+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
import UIKit

extension STPPaymentMethod: STPPaymentOption {
    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card, let card = card {
            return STPImageLibrary.cardBrandImage(for: card.brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card, let card = card {
            return STPImageLibrary.templatedBrandImage(for: card.brand)
        } else {
            return STPImageLibrary.templatedBrandImage(for: .unknown)
        }
    }

    @objc public var label: String {
        switch type {
        case .card:
            if let card = card {
                let brand = STPCardBrandUtilities.stringFrom(card.brand)
                return "\(brand ?? "") \(card.last4 ?? "")"
            } else {
                return STPCardBrandUtilities.stringFrom(.unknown) ?? ""
            }
        case .FPX:
            if let fpx = fpx {
                return STPFPXBank.stringFrom(STPFPXBank.brandFrom(fpx.bankIdentifierCode)) ?? ""
            } else {
                fallthrough
            }
        case .USBankAccount:
            if let usBankAccount = usBankAccount {
                return String(
                    format: String.Localized.bank_name_account_ending_in_last_4,
                    usBankAccount.bankName,
                    usBankAccount.last4
                )
            } else {
                fallthrough
            }
        default:
            return type.displayName
        }
    }

    @objc public var isReusable: Bool {
        switch type {
        case .card, .link, .USBankAccount:
            return true
        case .alipay,  // Careful! Revisit this if/when we support recurring Alipay
            .AUBECSDebit,
            .bacsDebit, .SEPADebit, .iDEAL, .FPX, .cardPresent, .giropay, .EPS, .payPal,
            .przelewy24, .bancontact,
            .OXXO, .sofort, .grabPay, .netBanking, .UPI, .afterpayClearpay, .blik,
            .weChatPay, .boleto, .klarna, .linkInstantDebit, .affirm, .cashApp,  // fall through
            .unknown:
            return false
        @unknown default:
            return false
        }
    }
}
