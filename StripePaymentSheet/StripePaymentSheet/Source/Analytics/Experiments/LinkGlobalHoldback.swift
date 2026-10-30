//
//  LinkGlobalHoldback.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-02.
//

import Foundation

struct LinkGlobalHoldback: LoggableExperiment {
    static let experimentName = "link_global_holdback"
    private let baseExperiment: BaseLinkHoldbackExperiment

    let name: String = experimentName
    let arbId: String

    var group: ExperimentGroup {
        baseExperiment.group
    }

    var dimensions: [String: String] {
        baseExperiment.dimensionsDictionary
    }

    init(
        arbId: String,
        session elementsSession: STPElementsSession,
        isLinkEnabled: Bool,
        defaultBillingDetails: PaymentSheet.BillingDetails,
        linkAccount: PaymentSheetLinkAccount?,
        integrationShape: ExperimentIntegrationShape
    ) {
        let baseExperiment = BaseLinkHoldbackExperiment(
            experimentName: Self.experimentName,
            elementsSession: elementsSession,
            isLinkEnabled: isLinkEnabled,
            defaultBillingDetails: defaultBillingDetails,
            linkAccount: linkAccount,
            integrationShape: integrationShape
        )

        self.arbId = arbId
        self.baseExperiment = baseExperiment
    }
}
