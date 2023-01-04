//
//  STPSource+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
import UIKit

extension STPSource: STPPaymentOption {
    // MARK: - STPPaymentOption
    @objc public var image: UIImage {
        if type == .card, let cardDetails = cardDetails {
            return STPImageLibrary.cardBrandImage(for: cardDetails.brand)
        } else {
            return STPImageLibrary.cardBrandImage(for: .unknown)
        }
    }

    @objc public var templateImage: UIImage {
        if type == .card, let cardDetails = cardDetails {
            return STPImageLibrary.templatedBrandImage(for: cardDetails.brand)
        } else {
            return STPImageLibrary.templatedBrandImage(for: .unknown)
        }
    }

    @objc public var label: String {
        switch type {
        case .bancontact:
            return STPPaymentMethodType.bancontact.displayName
        case .card:
            if let cardDetails = cardDetails {
                let brand = STPCard.string(from: cardDetails.brand)
                return "\(brand) \(cardDetails.last4 ?? "")"
            } else {
                return STPCard.string(from: .unknown)
            }
        case .giropay:
            return STPPaymentMethodType.giropay.displayName
        case .iDEAL:
            return STPPaymentMethodType.iDEAL.displayName
        case .SEPADebit:
            return STPPaymentMethodType.SEPADebit.displayName
        case .sofort:
            return STPPaymentMethodType.sofort.displayName
        case .threeDSecure:
            return STPLocalizedString("3D Secure", "Source type brand name")
        case .alipay:
            return STPPaymentMethodType.alipay.displayName
        case .P24:
            return STPPaymentMethodType.przelewy24.displayName
        case .EPS:
            return STPPaymentMethodType.EPS.displayName
        case .multibanco:
            return STPLocalizedString("Multibanco", "Source type brand name")
        case .weChatPay:
            return STPPaymentMethodType.weChatPay.displayName
        case .klarna:
            return STPPaymentMethodType.klarna.displayName
        case .unknown:
            return STPPaymentMethodType.unknown.displayName
        @unknown default:
            return STPPaymentMethodType.unknown.displayName
        }
    }

    @objc public var isReusable: Bool {
        return usage != .singleUse
    }
}
