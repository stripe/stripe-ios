//
//  STPPaymentIntentShippingDetailsParams+PaymentSheet.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 8/3/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension STPPaymentIntentShippingDetailsParams {
    convenience init?(paymentSheetConfiguration: PaymentSheet.Configuration) {
        let shippingDetails = paymentSheetConfiguration.shippingDetails
        let address = shippingDetails.address
        guard let name = paymentSheetConfiguration.shippingDetails.name, let line1 = address.line1 else {
            return nil
        }
        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: line1)
        addressParams.line2 = address.line2
        addressParams.city = address.city
        addressParams.state = address.state
        addressParams.postalCode = address.postalCode
        addressParams.country = address.country
        
        self.init(address: addressParams, name: name)
        phone = shippingDetails.phone
    }
}
