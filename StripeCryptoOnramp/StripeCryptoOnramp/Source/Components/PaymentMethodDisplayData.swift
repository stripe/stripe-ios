//
//  PaymentMethodDisplayData.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 8/11/25.
//

import Foundation
@_spi(STP) import StripePaymentSheet
import UIKit

/// Represents the payment method currently selected by the user.
@_spi(CryptoOnrampAlpha)
public struct PaymentMethodDisplayData {

    /// Represents the type of selected payment method.
    public enum PaymentMethodType {

        /// The user chose a card-based payment method, such as a debit or credit card.
        case card

        /// The user chose a bank account for payment.
        case bankAccount

        /// The user chose Apple pay for payment.
        case applePay

        /// Creates a new instance of `PaymentMethodType` converting from `LinkController.PaymentMethodPreview.PaymentMethodType`.
        /// - Parameter paymentMethodType: The Link payment method type to convert from.
        init(paymentMethodType: LinkController.PaymentMethodPreview.PaymentMethodType) {
            switch paymentMethodType {
            case .card:
                self = .card
            case .bankAccount:
                self = .bankAccount
            @unknown default:
                self = .card
            }
        }
    }

    /// The type of the selected payment method.
    public let paymentMethodType: PaymentMethodType

    /// The payment method icon to render in your screen.
    public let icon: UIImage

    /// The payment method label to render in your screen. For instance, `Link` or `Apple Pay`.
    public let label: String

    /// Details about the underlying payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
    public let sublabel: String?

    /// A snapshot of the collected card, if available. Mutually exclusive with `bankAccountDetails`.
    public let cardDetails: OnrampCardDetails?

    /// A snapshot of the collected bank account, if available. Mutually exclusive with `cardDetails`.
    public let bankAccountDetails: OnrampBankAccountDetails?

    /// Creates a new instance of `PaymentMethodDisplayData` without structured instrument details.
    /// - Parameters:
    ///   - paymentMethodType: The type of the selected payment method.
    ///   - icon: The payment method icon to render in your screen.
    ///   - label: The payment method label to render in your screen. For instance, `Link` or `Apple Pay`.
    ///   - sublabel: Details about the underlying payment method. This will typically render the display name of the payment method followed by the last four digits, e.g. `Visa Credit •••• 4242`.
    public init(paymentMethodType: PaymentMethodType, icon: UIImage, label: String, sublabel: String?) {
        self.init(
            paymentMethodType: paymentMethodType,
            icon: icon,
            label: label,
            sublabel: sublabel,
            cardDetails: nil,
            bankAccountDetails: nil
        )
    }

    init(
        paymentMethodType: PaymentMethodType,
        icon: UIImage,
        label: String,
        sublabel: String?,
        cardDetails: OnrampCardDetails?,
        bankAccountDetails: OnrampBankAccountDetails?
    ) {
        self.paymentMethodType = paymentMethodType
        self.icon = icon
        self.label = label
        self.sublabel = sublabel
        self.cardDetails = cardDetails
        self.bankAccountDetails = bankAccountDetails
    }

    init(linkPreview: LinkController.PaymentMethodPreview) {
        let cardDetails: OnrampCardDetails?
        let bankAccountDetails: OnrampBankAccountDetails?
        switch linkPreview.instrumentDetails {
        case .card(let funding, let brand, let last4):
            cardDetails = OnrampCardDetails(funding: funding, brand: brand, last4: last4)
            bankAccountDetails = nil
        case .bankAccount(let last4):
            cardDetails = nil
            bankAccountDetails = OnrampBankAccountDetails(last4: last4)
        case nil:
            cardDetails = nil
            bankAccountDetails = nil
        @unknown default:
            cardDetails = nil
            bankAccountDetails = nil
        }
        self.init(
            paymentMethodType: .init(paymentMethodType: linkPreview.paymentMethodType),
            icon: linkPreview.icon,
            label: linkPreview.label,
            sublabel: linkPreview.sublabel,
            cardDetails: cardDetails,
            bankAccountDetails: bankAccountDetails
        )
    }
}
