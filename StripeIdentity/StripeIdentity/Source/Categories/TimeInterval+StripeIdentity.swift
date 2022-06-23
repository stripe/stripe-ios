//
//  TimeInterval+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 6/7/22.
//

import Foundation

extension TimeInterval {
    init(milliseconds: Int) {
        self = Double(milliseconds) / 1000
    }

    var milliseconds: Double {
        return self * 1000
    }
}
