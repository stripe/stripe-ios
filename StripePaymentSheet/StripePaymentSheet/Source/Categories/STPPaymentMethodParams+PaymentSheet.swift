//
//  STPPaymentMethodParams+PaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePaymentsUI

extension STPPaymentMethodParams {
    var nonnil_billingDetails: STPPaymentMethodBillingDetails {
        guard let billingDetails = billingDetails else {
            let billingDetails = STPPaymentMethodBillingDetails()
            self.billingDetails = billingDetails
            return billingDetails
        }
        return billingDetails
    }

    var nonnil_auBECSDebit: STPPaymentMethodAUBECSDebitParams {
        guard let auBECSDebit = auBECSDebit else {
            let auBECSDebit = STPPaymentMethodAUBECSDebitParams()
            self.auBECSDebit = auBECSDebit
            return auBECSDebit
        }
        return auBECSDebit
    }

    var nonnil_bacsDebit: STPPaymentMethodBacsDebitParams {
        guard let bacsDebit = bacsDebit else {
            let bacsDebit = STPPaymentMethodBacsDebitParams()
            self.bacsDebit = bacsDebit
            return bacsDebit
        }
        return bacsDebit
    }
}
