//
//  STPPaymentMethodParams+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePaymentsUI
import UIKit

extension STPPaymentMethodParams: STPPaymentOption {
    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card && card != nil {
            let brand = STPCardValidator.brand(forNumber: card?.number ?? "")
            return STPImageLibrary.cardBrandImage(for: brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card && card != nil {
            let brand = STPCardValidator.brand(forNumber: card?.number ?? "")
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
            .afterpayClearpay, .blik, .weChatPay, .boleto, .klarna, .linkInstantDebit, .affirm, .cashApp,
            .unknown:
            return false
        @unknown default:
            return false
        }
    }
}
