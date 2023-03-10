//
//  FinancialConnectionsAnalyticsClient.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/13/22.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

final class FinancialConnectionsAnalyticsClient {

    private let analyticsClient: AnalyticsClientV2
    private var additionalParameters: [String: Any] = [:]

    init(
        analyticsClient: AnalyticsClientV2 = AnalyticsClientV2(
            clientId: "mobile-clients-linked-accounts",
            origin: "stripe-linked-accounts-ios"
        )
    ) {
        self.analyticsClient = analyticsClient
        additionalParameters["is_webview"] = false
        additionalParameters["navigator_language"] = Locale.current.identifier
    }

    public func log(eventName: String, parameters: [String: Any] = [:]) {
        let eventName = "linked_accounts.\(eventName)"
        let parameters = parameters.merging(
            additionalParameters,
            uniquingKeysWith: { eventParameter, _ in
                // prioritize event `parameters` over `additionalParameters`
                return eventParameter
            }
        )

        assert(
            !parameters.contains(where: { $0.key == "duration" && type(of: $0.value) == TimeInterval.self }),
            "Duration is expected to be sent as an Int (miliseconds)."
        )
        assert(
            !parameters.contains(where: { type(of: $0.value) == FinancialConnectionsSessionManifest.NextPane.self }),
            "Do not pass NextPane enum. Use the raw value."
        )

        analyticsClient.log(eventName: eventName, parameters: parameters)
    }

    public func logExposure(
        experimentName: String,
        assignmentEventId: String,
        accountholderToken: String
    ) {
        var parameters = additionalParameters
        parameters["experiment_retrieved"] = experimentName
        parameters["arb_id"] = assignmentEventId
        parameters["account_holder_id"] = accountholderToken
        analyticsClient.log(eventName: "preloaded_experiment_retrieved", parameters: parameters)
    }
}

// MARK: - Helpers

extension FinancialConnectionsAnalyticsClient {

    func logPaneLoaded(pane: FinancialConnectionsSessionManifest.NextPane) {
        log(eventName: "pane.loaded", parameters: ["pane": pane.rawValue])
    }

    func logExpectedError(
        _ error: Error,
        errorName: String?,
        pane: FinancialConnectionsSessionManifest.NextPane?
    ) {
        log(
            error: error,
            errorName: errorName,
            eventName: "error.expected",
            pane: pane
        )
    }

    func logUnexpectedError(
        _ error: Error,
        errorName: String?,
        pane: FinancialConnectionsSessionManifest.NextPane?
    ) {
        log(
            error: error,
            errorName: errorName,
            eventName: "error.unexpected",
            pane: pane
        )
    }

    private func log(
        error: Error,
        errorName: String?,
        eventName: String,
        pane: FinancialConnectionsSessionManifest.NextPane?
    ) {
        var parameters: [String: Any] = [:]
        parameters["pane"] = pane?.rawValue
        parameters["error"] = errorName
        if let stripeError = error as? StripeError,
            case .apiError(let apiError) = stripeError
        {
            parameters["error_type"] = apiError.type.rawValue
            parameters["error_message"] = apiError.message
            parameters["code"] = apiError.code
        } else {
            parameters["error_type"] = (error as NSError).domain
            parameters["error_message"] = (error as NSError).localizedDescription
            parameters["code"] = (error as NSError).code
        }
        log(eventName: eventName, parameters: parameters)
    }

    func logMerchantDataAccessLearnMore(pane: FinancialConnectionsSessionManifest.NextPane) {
        log(
            eventName: "click.data_access.learn_more",
            parameters: ["pane": pane.rawValue]
        )
    }

    func setAdditionalParameters(
        linkAccountSessionClientSecret: String,
        publishableKey: String?,
        stripeAccount: String?
    ) {
        additionalParameters["las_client_secret"] = linkAccountSessionClientSecret
        additionalParameters["key"] = publishableKey
        additionalParameters["stripe_account"] = stripeAccount
    }

    func setAdditionalParameters(fromManifest manifest: FinancialConnectionsSessionManifest) {
        additionalParameters["livemode"] = manifest.livemode
        additionalParameters["product"] = manifest.product
        additionalParameters["is_stripe_direct"] = manifest.isStripeDirect
        additionalParameters["single_account"] = manifest.singleAccount
        additionalParameters["allow_manual_entry"] = manifest.allowManualEntry
        additionalParameters["account_holder_id"] = manifest.accountholderToken
    }

    @available(iOSApplicationExtension, unavailable)
    static func paneFromViewController(
        _ viewController: UIViewController?
    ) -> FinancialConnectionsSessionManifest.NextPane {
        switch viewController {
        case is ConsentViewController:
            return .consent
        case is InstitutionPickerViewController:
            return .institutionPicker
        case is PartnerAuthViewController:
            return .partnerAuth
        case is AccountPickerViewController:
            return .accountPicker
        case is AttachLinkedPaymentAccountViewController:
            return .attachLinkedPaymentAccount
        case is SuccessViewController:
            return .success
        case is ManualEntryViewController:
            return .manualEntry
        case is ManualEntrySuccessViewController:
            return .manualEntrySuccess
        case is ResetFlowViewController:
            return .resetFlow
        case is TerminalErrorViewController:
            return .terminalError
        default:
            return .unparsable
        }
    }
}
