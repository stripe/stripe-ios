//
//  Analytic.swift
//  StripeiOS Tests
//
//  Created by Mel Ludowise on 3/12/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// An analytic that can be logged to our analytics system
protocol Analytic {
    var event: STPAnalyticEvent { get }
    var params: [String: Any] { get }
}

/**
 A generic analytic type.
 - NOTE: This should only be used to support legacy analytics.
 Any new analytic events should create a new type and conform to `Analytic`.
 */
struct GenericAnalytic: Analytic {
    let event: STPAnalyticEvent
    let params: [String : Any]
}
