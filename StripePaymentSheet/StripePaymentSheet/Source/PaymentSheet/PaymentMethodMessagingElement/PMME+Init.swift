//
//
//  PMME+Init.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/15/25.
//

import StripeCore
import StripePayments
import UIKit

// public structs don't automatically synthesize these initializers so we have to explicitly provide them

public extension PaymentMethodMessagingElement.Appearance {
    init(
        style: UserInterfaceStyle? = nil,
        font: UIFont? = nil,
        textColor: UIColor? = nil,
        infoIconColor: UIColor? = nil
    ) {
        if let style { self.style = style }
        if let font { self.font = font }
        if let textColor { self.textColor = textColor }
        if let infoIconColor { self.infoIconColor = infoIconColor }
    }
}

public extension PaymentMethodMessagingElement.Configuration {
    init(
        amount: Int,
        currency: String,
        apiClient: STPAPIClient? = nil,
        locale: String? = nil,
        countryCode: String? = nil,
        paymentMethodTypes: [STPPaymentMethodType]? = nil,
        appearance: PaymentMethodMessagingElement.Appearance? = nil
    ) {
        self.amount = amount
        self.currency = currency
        if let apiClient { self.apiClient = apiClient }
        if let locale { self.locale = locale }
        if let countryCode { self.countryCode = countryCode }
        if let paymentMethodTypes { self.paymentMethodTypes = paymentMethodTypes }
        if let appearance { self.appearance = appearance }
    }
}
