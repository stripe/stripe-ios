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
        let source = billingDetails.address
        let address = Address(
            country: country,
            line1: source?.line1?.isEmpty == true ? nil : source?.line1,
            line2: source?.line2?.isEmpty == true ? nil : source?.line2,
            city: source?.city?.isEmpty == true ? nil : source?.city,
            state: source?.state?.isEmpty == true ? nil : source?.state,
            postalCode: source?.postalCode?.isEmpty == true ? nil : source?.postalCode
        )
        try await updateBillingAddress(
            name: billingDetails.name,
            phone: billingDetails.phone,
            address: address,
            calledFromSheet: true
        )
    }
}
