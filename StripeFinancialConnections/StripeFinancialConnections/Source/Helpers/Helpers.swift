//
//  Foundation.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

func assertMainQueue() {
    #if DEBUG
    dispatchPrecondition(condition: .onQueue(DispatchQueue.main))
    #endif
}
