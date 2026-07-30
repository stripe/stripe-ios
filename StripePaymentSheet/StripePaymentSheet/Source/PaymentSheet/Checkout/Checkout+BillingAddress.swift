//
//  Checkout+BillingAddress.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/7/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension Checkout {
    /// Whether selecting a payment method with the given billing details requires a server update
    /// to keep Checkout automatic tax in sync.
    func requiresBillingAddressSync(from billingDetails: STPPaymentMethodBillingDetails?) -> Bool {
        return session.collectsTaxFromBillingAddress
            && billingDetails?.address?.country?.nonEmpty != nil
    }

    /// Syncs the payment method's billing address to Checkout tax calculation when needed.
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        // We need at least a country to build an Address for tax region calculation. Billing details
        // are optional on payment methods, so it's fine to just skip if we don't have enough info.
        guard requiresBillingAddressSync(from: billingDetails),
              let billingDetails,
              let country = billingDetails.address?.country?.nonEmpty else {
            return
        }
        let source = billingDetails.address
        let address = Address(
            country: country,
            line1: source?.line1?.nonEmpty,
            line2: source?.line2?.nonEmpty,
            city: source?.city?.nonEmpty,
            state: source?.state?.nonEmpty,
            postalCode: source?.postalCode?.nonEmpty
        )
        try await updateBillingTaxRegionIfNecessary(
            address: address,
            canUpdateWhileSheetPresented: true
        )
    }
}
