//
//  BaseLinkHoldbackExperiment.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 5/21/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct BaseLinkHoldbackExperiment {
    let group: ExperimentGroup

    let defaultValuesProvided: String
    let hasSPMs: Bool
    let integrationShape: String
    let isReturningLinkUser: Bool
    let linkDefaultOptIn: String
    let linkDisplayed: Bool
    let linkNative: Bool
    let sdkVersion: String
    let elementsSessionId: String
    let mobileSessionId: String

    var dimensionsDictionary: [String: Any] {
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
            "mobile_sdk_version": sdkVersion,
            "elements_session_id": elementsSessionId,
            "mobile_session_id": mobileSessionId,
        ]
    }

    init(
        experimentName: String,
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        linkAccount: PaymentSheetLinkAccount?,
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape
    ) {
        let isLinkEnabled = PaymentSheet.isLinkEnabled(
            elementsSession: elementsSession,
            configuration: configuration
        )

        // In some scenarios (i.e. testmode) there will be no group assignment.
        // Treat these scenarios as though we're in the control group.
        let assignment = elementsSession.experimentsData?.experimentAssignments[experimentName]
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

        self.sdkVersion = StripeAPIConfiguration.STPSDKVersion
        self.elementsSessionId = elementsSession.sessionID
        self.mobileSessionId = AnalyticsHelper.shared.sessionID ?? "N/a"
    }
}
