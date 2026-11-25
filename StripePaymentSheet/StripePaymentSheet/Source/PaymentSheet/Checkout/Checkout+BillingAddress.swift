//
//  Checkout+BillingAddress.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 7/7/26.
//

import Foundation
import PassKit
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

extension CheckoutSessionBillingAddressUpdater {
    /// Syncs the payment method's billing address to Checkout tax calculation when needed.
    func syncBillingAddress(from billingDetails: STPPaymentMethodBillingDetails?) async throws {
        // Billing details are optional on payment methods, so it's fine to just skip if we don't have enough info.
        guard let address = CheckoutElementsController.Address(taxRegionFrom: billingDetails?.address) else {
            return
        }
        _ = try await updateBillingTaxRegionIfNecessaryForPaymentSheet(
            address: address,
            canUpdateWhileSheetPresented: true
        )
    }
}

extension CheckoutElementsController.Address {
    /// Creates a tax region from a payment method address, e.g. a billing or shipping address.
    /// Returns nil without a country, since there's nothing to calculate tax from.
    init?(taxRegionFrom address: STPPaymentMethodAddress?) {
        guard let country = address?.country?.nonEmpty else {
            return nil
        }
        self.init(
            country: country,
            line1: address?.line1?.nonEmpty,
            line2: address?.line2?.nonEmpty,
            city: address?.city?.nonEmpty,
            state: address?.state?.nonEmpty,
            postalCode: address?.postalCode?.nonEmpty
        )
    }
}
