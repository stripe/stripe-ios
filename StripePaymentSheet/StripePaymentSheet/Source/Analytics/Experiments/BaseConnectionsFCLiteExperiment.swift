//
//  BaseConnectionsFCLiteExperiment.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2026-06-02.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct BaseConnectionsFCLiteExperiment {
    let group: ExperimentGroup

    private let elementsSessionId: String
    private let mobileSessionId: String
    private let sdkVersion: String
    private let fcSdkAvailability: String
    private let availableLPMs: String

    var dimensionsDictionary: [String: String] {
        [
            "elements_session_id": elementsSessionId,
            "mobile_session_id": mobileSessionId,
            "mobile_sdk_version": sdkVersion,
            "fc_sdk_availability": fcSdkAvailability,
            "available_lpms": availableLPMs,
        ]
    }

    init(experimentName: String, elementsSession: STPElementsSession) {
        let assignment = elementsSession.experimentsData?.experimentAssignments[experimentName]
        self.group = assignment ?? .control
        self.elementsSessionId = elementsSession.sessionID
        self.mobileSessionId = AnalyticsHelper.shared.sessionID ?? "N/a"
        self.sdkVersion = StripeAPIConfiguration.STPSDKVersion
        self.fcSdkAvailability = FinancialConnectionsSDKAvailability.analyticsValue
        self.availableLPMs = elementsSession.orderedPaymentMethodTypesAndWallets.joined(separator: ",")
    }
}
