//
//  CheckoutPaymentMethodUpdateTypes.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 6/29/26.
//

import Foundation
@_spi(STP) import StripePayments

extension Checkout {

    struct PaymentMethodBillingDetails {
        let name: String?
        let email: String?
        let phone: String?
        let address: PaymentMethodBillingAddress?

        init(name: String? = nil, email: String? = nil, phone: String? = nil, address: PaymentMethodBillingAddress? = nil) {
            self.name = name
            self.email = email
            self.phone = phone
            self.address = address
        }

        init?(_ billing: STPPaymentMethodBillingDetails?) {
            guard let billing else { return nil }
            let address: PaymentMethodBillingAddress? = {
                guard let addr = billing.address else { return nil }
                guard addr.line1 != nil || addr.line2 != nil || addr.city != nil || addr.state != nil || addr.postalCode != nil || addr.country != nil else {
                    return nil
                }
                return PaymentMethodBillingAddress(
                    line1: addr.line1,
                    line2: addr.line2,
                    city: addr.city,
                    state: addr.state,
                    postalCode: addr.postalCode,
                    country: addr.country
                )
            }()
            guard billing.name != nil || billing.email != nil || billing.phone != nil || address != nil else {
                return nil
            }
            self.init(
                name: billing.name,
                email: billing.email,
                phone: billing.phone,
                address: address
            )
        }
    }

    struct PaymentMethodBillingAddress {
        let line1: String?
        let line2: String?
        let city: String?
        let state: String?
        let postalCode: String?
        let country: String?

        init(line1: String? = nil, line2: String? = nil, city: String? = nil, state: String? = nil, postalCode: String? = nil, country: String? = nil) {
            self.line1 = line1
            self.line2 = line2
            self.city = city
            self.state = state
            self.postalCode = postalCode
            self.country = country
        }
    }

    struct PaymentMethodExpiryDetails {
        let expMonth: Int
        let expYear: Int

        init(expMonth: Int, expYear: Int) {
            self.expMonth = expMonth
            self.expYear = expYear
        }

        init?(_ card: STPPaymentMethodCardParams?) {
            guard let card,
                  let month = card.expMonth?.intValue,
                  let year = card.expYear?.intValue else {
                return nil
            }
            let fullYear = year < 100 ? year + 2000 : year
            guard fullYear >= 2000 else { return nil }
            self.init(expMonth: month, expYear: fullYear)
        }
    }
}
