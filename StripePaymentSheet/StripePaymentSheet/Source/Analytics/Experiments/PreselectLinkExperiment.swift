import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

struct PreselectLinkExperiment: LoggableExperiment {
    static let experimentName = "ocs_mobile_preselect_link"

    let name = experimentName
    let arbId: String
    let group: ExperimentGroup
    let dimensions: [String: String]

    @MainActor
    static func shouldPreselectLink(
        elementsSession: STPElementsSession,
        configuration: PaymentElementConfiguration,
        integrationShape: PaymentSheetLoader.IntegrationShape,
        hasExistingSelection: Bool,
        isApplePayEnabled: Bool,
        savedPaymentMethods: [STPPaymentMethod],
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        linkAccount: PaymentSheetLinkAccount?,
        analyticsHelper: ExperimentAnalyticsHelper
    ) -> Bool {
        guard integrationShape.canDefaultToLinkOrApplePay,
              !hasExistingSelection,
              configuration.link.display == .automatic,
              (configuration as? PaymentSheet.Configuration)?.willUseWalletButtonsView != true,
              PaymentSheet.shouldShowLinkButton(elementsSession: elementsSession, configuration: configuration),
              let experimentsData = elementsSession.experimentsData,
              let group = experimentsData.experimentAssignments[experimentName],
              [.control, .controlTest, .treatment].contains(group) else {
            return false
        }

        let linkLoginState: String
        switch linkAccount?.sessionState {
        case .verified:
            linkLoginState = "logged_in"
        case .requiresVerification:
            linkLoginState = deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) ? "needs_verification" : "needs_web_verification"
        case .requiresSignUp, nil:
            linkLoginState = "logged_out"
        }
        let paymentMethodTypeNames = paymentMethodTypes.map { $0.identifier }
        let paymentMethodTypesIncludingWallets = paymentMethodTypeNames + (isApplePayEnabled ? ["apple_pay"] : []) + ["link"]
        let experiment = PreselectLinkExperiment(
            arbId: experimentsData.arbId ?? "",
            group: group,
            dimensions: [
                "in_app_elements_integration_type": analyticsHelper.integrationShape.rawValue,
                "displayed_payment_method_types": paymentMethodTypeNames.joined(separator: ","),
                "displayed_payment_method_types_including_wallets": paymentMethodTypesIncludingWallets.joined(separator: ","),
                "link_enabled": "true",
                "link_login_state": linkLoginState,
                "apple_pay_enabled": isApplePayEnabled.description,
                "has_saved_payment_method": (!savedPaymentMethods.isEmpty).description,
                "elements_session_id": elementsSession.sessionID,
                "mobile_session_id": AnalyticsHelper.shared.sessionID ?? "N/a",
                "mobile_sdk_version": StripeAPIConfiguration.STPSDKVersion,
            ]
        )
        analyticsHelper.logExposure(experiment: experiment)
        return group == .treatment
    }
}
