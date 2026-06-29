//
//  Checkout+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/29/26.
//

import Foundation
@_spi(STP) import StripePayments

extension Checkout {
    /// Syncs the billing address on the checkout session from the selected payment method.
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        guard let billingDetails,
              let country = billingDetails.address?.country, !country.isEmpty else {
            return
        }
        let a = billingDetails.address
        let address = Address(
            country: country,
            line1: a?.line1?.isEmpty == true ? nil : a?.line1,
            line2: a?.line2?.isEmpty == true ? nil : a?.line2,
            city: a?.city?.isEmpty == true ? nil : a?.city,
            state: a?.state?.isEmpty == true ? nil : a?.state,
            postalCode: a?.postalCode?.isEmpty == true ? nil : a?.postalCode
        )
        try await updateBillingAddress(
            name: billingDetails.name,
            phone: billingDetails.phone,
            address: address,
            calledFromSheet: true
        )
    }
}
