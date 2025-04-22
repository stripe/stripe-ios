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

    private let defaultValuesProvided: String
    private let hasSPMs: Bool
    private let integrationShape: String
    private let isReturningLinkUser: Bool
    private let linkDefaultOptIn: String
    private let linkDisplayed: Bool
    private let linkNative: Bool

    var dimensions: [String: Any] {
        [
            "dvs_provided": defaultValuesProvided,
            "has_spms": hasSPMs,
            "integration_shape": integrationShape,
            "integration_type": "mpe_ios",
            "is_returning_link_user": isReturningLinkUser,
            "link_default_opt_in": linkDefaultOptIn,
            "link_displayed": linkDisplayed,
            "link_native": linkNative,
            "recognition_type": "email",
        ]
    }

    init?(
        session elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) {
        guard let arbId = elementsSession.experimentsData?.arbId else {
            return nil
        }
        self.arbId = arbId

        let isLinkEnabled = PaymentSheet.isLinkEnabled(
            elementsSession: elementsSession,
            configuration: configuration
        )

        // In some scenarios (i.e. testmode) there will be no group assignment.
        // Treat these scenarios as though we're in the control group.
        let assignment = elementsSession.experimentsData?.experimentAssignments[name]
        self.group = assignment ?? .control

        // A non-nil consumer session represents an existing Link user.
        self.isReturningLinkUser = linkAccount?.currentSession != nil
        self.linkNative = linkAccount?.useMobileEndpoints == true
        self.linkDefaultOptIn = (elementsSession.linkSettings?.linkDefaultOptIn ?? .none).rawValue
        self.integrationShape = integrationShape.analyticsValue
        self.linkDisplayed = isLinkEnabled

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
        self.defaultValuesProvided = defaultValuesProvided.joined(separator: " ")

        // SPM is enabled when:
        // 1. Session has a valid customer
        // 2. Payment Method Save is enabled
        // 3. Link is not enabled (unless an additional beta flag is enabled)
        let hasCustomer = elementsSession.customer != nil
        let paymentMethodSaveEnabled = elementsSession.customerSessionMobilePaymentElementFeatures?.paymentMethodSave == true
        let linkNotEnabledOrEnableLinkSPMFlag = !isLinkEnabled || elementsSession.flags["elements_enable_link_spm"] == true
        self.hasSPMs = hasCustomer && paymentMethodSaveEnabled && linkNotEnabledOrEnableLinkSPMFlag
    }
}
