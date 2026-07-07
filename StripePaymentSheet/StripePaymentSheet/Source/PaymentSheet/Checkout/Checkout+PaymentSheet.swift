//
//  Checkout+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/7/26.
//

import Foundation
@_spi(STP) import StripePayments

extension Checkout {
    /// Syncs the billing address on the checkout session from the selected payment method's billing details.
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        guard let billingDetails,
              let country = billingDetails.address?.country, !country.isEmpty else {
            return
        }
        let source = billingDetails.address
        let address = Address(
            country: country,
            line1: source?.line1?.nilIfEmpty,
            line2: source?.line2?.nilIfEmpty,
            city: source?.city?.nilIfEmpty,
            state: source?.state?.nilIfEmpty,
            postalCode: source?.postalCode?.nilIfEmpty
        )
        try await updateBillingAddress(
            name: billingDetails.name,
            phone: billingDetails.phone,
            address: address
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
