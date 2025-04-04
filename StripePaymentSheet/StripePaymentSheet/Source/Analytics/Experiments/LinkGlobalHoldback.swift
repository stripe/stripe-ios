//
//  LinkGlobalHoldback.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-02.
//

import Foundation
@_spi(STP) import StripePayments

struct LinkGlobalHoldback: LoggableExperiment {
    let name: String = "link_global_holdback"
    let arbId: String
    let group: ExperimentGroup

    private let isReturningLinkUser: Bool
    private let isLinkNative: Bool
    private let linkDefaultOptIn: String
    private let defaultValuesProvided: [String]

    var dimensions: [String: Any] {
        [
            "integration_type": "mpe_ios",
            "link_default_opt_in": linkDefaultOptIn,
            "is_returning_link_user": isReturningLinkUser,
            "dvs_provided": defaultValuesProvided,
            "recognition_type": "email",
            "link_native": isLinkNative,
        ]
    }

    init?(
        session elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?
    ) {
        guard let arbId = elementsSession.experimentsData?.arbId else {
            return nil
        }
        self.arbId = arbId

        // In some scenarios (i.e. testmode) there will be no group assignment.
        // Treat these scenarios as though we're in the control group.
        let assignment = elementsSession.experimentsData?.experimentAssignments[name]
        self.group = assignment ?? .control

        // A non-nil consumer session represents an existing Link user.
        self.isReturningLinkUser = linkAccount?.currentSession != nil
        self.isLinkNative = linkAccount?.useMobileEndpoints == true
        self.linkDefaultOptIn = elementsSession.linkSettings?.linkDefaultOptIn?.rawValue ?? "NONE"

        var defaultValuesProvided: [String] = []
        if configuration.defaultBillingDetails.email != nil {
            defaultValuesProvided.append("email")
        }
        if configuration.defaultBillingDetails.name != nil {
            defaultValuesProvided.append("name")
        }
        if configuration.defaultBillingDetails.phone != nil {
            defaultValuesProvided.append("phone")
        }
        self.defaultValuesProvided = defaultValuesProvided
    }
}
