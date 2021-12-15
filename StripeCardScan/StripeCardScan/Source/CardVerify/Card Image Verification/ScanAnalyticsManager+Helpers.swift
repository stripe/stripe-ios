//
//  ScanAnalyticsManager+Helpers.swift
//  StripeCardScan
//
//  Created by Jaime Park on 12/9/21.
//

import UIKit

extension Date {
    var millisecondsSince1970: Int {
        Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}

extension TimeInterval {
    var milliseconds: Int {
        Int((self * 1000.0).rounded())
    }
}
