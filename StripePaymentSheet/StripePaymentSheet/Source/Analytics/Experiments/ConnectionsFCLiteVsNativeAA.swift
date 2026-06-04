//
//  ConnectionsFCLiteVsNativeAA.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2026-06-02.
//

import Foundation

struct ConnectionsFCLiteVsNativeAA: LoggableExperiment {
    static let experimentName = "connections_fc_lite_vs_native_aa"
    private let baseExperiment: BaseConnectionsFCLiteExperiment

    let name: String = experimentName
    let arbId: String

    var group: ExperimentGroup { baseExperiment.group }
    var dimensions: [String: String] { baseExperiment.dimensionsDictionary }

    init(arbId: String, session elementsSession: STPElementsSession) {
        self.arbId = arbId
        self.baseExperiment = BaseConnectionsFCLiteExperiment(
            experimentName: Self.experimentName,
            elementsSession: elementsSession
        )
    }
}
