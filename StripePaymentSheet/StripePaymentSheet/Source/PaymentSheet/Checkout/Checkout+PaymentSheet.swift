//
//  Checkout+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/29/26.
//

import Foundation
@_spi(STP) import StripePayments

extension Checkout {
    /// Updates the checkout billing address from the payment method's billing details.
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        guard let billingDetails,
              let country = billingDetails.address?.country, !country.isEmpty else {
            return
        }
        let address = Address(
            country: country,
            line1: billingDetails.address?.line1,
            line2: billingDetails.address?.line2,
            city: billingDetails.address?.city,
            state: billingDetails.address?.state,
            postalCode: billingDetails.address?.postalCode
        )
        try await updateBillingAddress(
            name: billingDetails.name,
            phone: billingDetails.phone,
            address: address,
            skipSheetPresentedCheck: true
        )
    }
}
