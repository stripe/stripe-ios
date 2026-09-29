//
//  Checkout+BillingAddress.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/7/26.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension CheckoutSessionBillingAddressUpdater {
    /// Syncs the payment method's billing address to Checkout tax calculation when needed.
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        // We need at least a country to build an Address for tax region calculation. Billing details
        // are optional on payment methods, so it's fine to just skip if we don't have enough info.
        guard let billingDetails,
              let country = billingDetails.address?.country?.nonEmpty else {
            return
        }
        let source = billingDetails.address
        let address = CheckoutController.Address(
            country: country,
            line1: source?.line1?.nonEmpty,
            line2: source?.line2?.nonEmpty,
            city: source?.city?.nonEmpty,
            state: source?.state?.nonEmpty,
            postalCode: source?.postalCode?.nonEmpty
        )
        _ = try await updateBillingTaxRegionIfNecessaryForPaymentSheet(
            address: address,
            canUpdateWhileSheetPresented: true
        )
    }
}
