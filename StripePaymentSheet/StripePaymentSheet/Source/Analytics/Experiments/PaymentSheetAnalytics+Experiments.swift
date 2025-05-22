//
//  PaymentSheetAnalytics+Experiments.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-02.
//

import Foundation
@_spi(STP) import StripeCore

protocol LoggableExperiment {
    var name: String { get }
    var arbId: String { get }
    var group: ExperimentGroup { get }
    var dimensions: [String: Any] { get }
}

extension PaymentSheetAnalyticsHelper {
    static let eventName = "elements.experiment_exposure"

    func logExposure(experiment: LoggableExperiment) {
        var parameters: [String: Any] = [:]
        parameters["arb_id"] = experiment.arbId
        parameters["experiment_retrieved"] = experiment.name
        parameters["assignment_group"] = experiment.group.rawValue

        for (key, value) in experiment.dimensions {
            parameters["dimensions-\(key)"] = value
        }

        // Make sure we log to `r.stripe.com` via `analyticsClientV2`:
        analyticsClientV2.log(eventName: Self.eventName, parameters: parameters)
    }
}
