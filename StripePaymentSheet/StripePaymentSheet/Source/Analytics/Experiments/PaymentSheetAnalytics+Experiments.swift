//
//  PaymentSheetAnalytics+Experiments.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-02.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

enum ExperimentIntegrationShape: String {
    case paymentSheet = "paymentsheet"
    case flowController = "flowcontroller"
    case embedded
    case linkController = "linkcontroller"
    case checkoutElements = "checkoutelements"
}

protocol LoggableExperiment {
    var name: String { get }
    var arbId: String { get }
    var group: ExperimentGroup { get }
    var dimensions: [String: String] { get }
}

extension PaymentSheetAnalyticsHelper {
    var experimentAnalyticsHelper: ExperimentAnalyticsHelper {
        ExperimentAnalyticsHelper(integrationShape: integrationShapeForExperiments, analyticsClientV2: analyticsClientV2)
    }

    var integrationShapeForExperiments: ExperimentIntegrationShape {
        switch integrationShape {
        case .complete:
            return .paymentSheet
        case .flowController:
            return .flowController
        case .embedded:
            return .embedded
        case .linkController:
            return .linkController
        }
    }
}

final class ExperimentAnalyticsHelper {
    static let eventName = "elements.experiment_exposure"
    let integrationShape: ExperimentIntegrationShape
    private let analyticsClientV2: AnalyticsClientV2Protocol

    init(
        integrationShape: ExperimentIntegrationShape,
        analyticsClientV2: AnalyticsClientV2Protocol = AnalyticsClientV2(
            clientId: "stripe-mobile-sdk",
            origin: "stripe-mobile-sdk-ios"
        )
    ) {
        self.integrationShape = integrationShape
        self.analyticsClientV2 = analyticsClientV2
    }

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
