//
//  PaymentSheet-Configuration+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 2/18/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

extension PaymentSheet.Configuration {

    var isApplePayEnabled: Bool {
        return StripeAPI.deviceSupportsApplePay() && self.applePay != nil
    }

}
