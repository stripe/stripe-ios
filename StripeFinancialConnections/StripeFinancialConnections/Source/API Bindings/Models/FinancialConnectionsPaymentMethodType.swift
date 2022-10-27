//
//  FinancialConnectionsPaymentMethodType.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

enum FinancialConnectionsPaymentMethodType: String, SafeEnumCodable, Equatable {
    case usBankAccount = "us_bank_account"
    case link = "link"
    case unparsable
}
