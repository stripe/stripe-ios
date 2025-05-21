//
//  LinkABTest.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 5/21/25.
//

import Foundation

struct LinkABTest: LoggableExperiment {
    private static let experimentName = "link_ab_test"
    private let baseExperiment: BaseLinkExperiment

    let name: String = experimentName
    let arbId: String
    let group: ExperimentGroup

    var dimensions: [String: Any] {
        return baseExperiment.dimensionsDictionary
    }

    init(
        arbId: String,
        session elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) {
        let baseExperiment = BaseLinkExperiment(
            experimentName: Self.experimentName,
            arbId: arbId,
            elementsSession: elementsSession,
            configuration: configuration,
            linkAccount: linkAccount,
            integrationShape: integrationShape
        )

        self.baseExperiment = baseExperiment
        self.arbId = arbId
        self.group = baseExperiment.group
    }
}
