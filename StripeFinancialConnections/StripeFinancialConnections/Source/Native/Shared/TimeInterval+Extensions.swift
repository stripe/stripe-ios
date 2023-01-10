//
//  TimeInterval+Extensions.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/28/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension TimeInterval {

    var milliseconds: Int {
        return Int(self * 1_000)
    }
}
