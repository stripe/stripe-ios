//
//  InstantDebitsLinkedBankImplementation.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) import StripeCore
import UIKit

struct InstantDebitsLinkedBankImplementation: InstantDebitsLinkedBank {
    public let paymentMethodId: String
    public let bankName: String?
    public let last4: String?

    public init(
        paymentMethodId: String,
        bankName: String?,
        last4: String?
    ) {
        self.paymentMethodId = paymentMethodId
        self.bankName = bankName
        self.last4 = last4
    }
}
