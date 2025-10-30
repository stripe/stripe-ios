//
//  LinkGlobalHoldback.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-02.
//

import Foundation

struct LinkGlobalHoldback: LoggableExperiment {
    private static let experimentName = "link_global_holdback"
    private let baseExperiment: BaseLinkHoldbackExperiment

    let name: String = experimentName
    let arbId: String

    var group: ExperimentGroup {
        baseExperiment.group
    }

    var dimensions: [String: Any] {
        baseExperiment.dimensionsDictionary
    }

    init(
        arbId: String,
        session elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) {
        let baseExperiment = BaseLinkHoldbackExperiment(
            experimentName: Self.experimentName,
            elementsSession: elementsSession,
            configuration: configuration,
            linkAccount: linkAccount,
            integrationShape: integrationShape
        )

        self.arbId = arbId
        self.baseExperiment = baseExperiment
    }
}
