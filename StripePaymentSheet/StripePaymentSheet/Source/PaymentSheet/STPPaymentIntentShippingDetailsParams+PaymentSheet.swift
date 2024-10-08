//
//  STPPaymentIntentShippingDetailsParams+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

extension STPPaymentIntentShippingDetailsParams {
    convenience init?(paymentSheetConfiguration: PaymentElementConfiguration) {
        guard let shippingDetails = paymentSheetConfiguration.shippingDetails() else {
            return nil
        }
        let address = shippingDetails.address
        guard let name = shippingDetails.name else {
            return nil
        }
        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: address.line1)
        addressParams.line2 = address.line2
        addressParams.city = address.city
        addressParams.state = address.state
        addressParams.postalCode = address.postalCode
        addressParams.country = address.country

        self.init(address: addressParams, name: name)
        phone = shippingDetails.phone
    }
}
