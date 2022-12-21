//
//  TimeInterval+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension TimeInterval {
    init(
        milliseconds: Int
    ) {
        self = Double(milliseconds) / 1000
    }

    var milliseconds: Double {
        return self * 1000
    }
}
