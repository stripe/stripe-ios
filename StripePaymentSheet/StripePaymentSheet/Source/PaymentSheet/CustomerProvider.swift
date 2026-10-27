//
//  CustomerProvider.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/27/26.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// Provides a common view of customer data and capabilities across PaymentSheet integrations.
struct CustomerProvider {

    private enum Backing {

        case customer(PaymentSheet.CustomerConfiguration?)
        case checkoutSession(CheckoutController.Session)
    }

    private let backing: Backing

    init(customer: PaymentSheet.CustomerConfiguration?) {
        backing = .customer(customer)
    }

    init(checkoutSession: CheckoutController.Session) {
        backing = .checkoutSession(checkoutSession)
    }

    var customerID: String? {
        switch backing {
        case .customer(let customer):
            return customer?.id
        case .checkoutSession(let session):
            return session.customer?.id
        }
    }

    var hasCustomer: Bool {
        return customerID != nil
    }
}
