//
//  FinancialConnectionsAnalyticsClient.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/13/22.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

protocol FinancialConnectionsAnalyticsClientDelegate: AnyObject {
    func analyticsClient(
        _ analyticsClient: FinancialConnectionsAnalyticsClient,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

final class FinancialConnectionsAnalyticsClient {

    private let analyticsClient: AnalyticsClientV2Protocol
    private var additionalParameters: [String: Any] = [:]
    weak var delegate: FinancialConnectionsAnalyticsClientDelegate?

    init(
        analyticsClient: AnalyticsClientV2Protocol = AnalyticsClientV2(
            clientId: "mobile-clients-linked-accounts",
            origin: "stripe-linked-accounts-ios"
        )
    ) {
        self.analyticsClient = analyticsClient
        additionalParameters["is_webview"] = false
        additionalParameters["navigator_language"] = Locale.current.toLanguageTag()
    }

    public func log(
        eventName: String,
        parameters: [String: Any] = [:],
        pane: FinancialConnectionsSessionManifest.NextPane
    ) {
        let eventName = "linked_accounts.\(eventName)"

        var parameters = parameters
        // !!! BE CAREFUL MODIFYING "PANE" ANALYTICS CODE
        // ITS CRITICAL FOR PANE CONVERSION !!!
        assert(parameters["pane"] == nil, "Unexpected logic: will override 'pane' parameter.")
        parameters["pane"] = pane.rawValue
        parameters = parameters.merging(
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
        assert((parameters["pane"] as? String) != nil, "We expect pane to be set as a String for all analytics events.")
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
        log(eventName: "pane.loaded", pane: pane)
    }

    func logExpectedError(
        _ error: Error,
        errorName: String,
        pane: FinancialConnectionsSessionManifest.NextPane
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
        errorName: String,
        pane: FinancialConnectionsSessionManifest.NextPane
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
        errorName: String,
        eventName: String,
        pane: FinancialConnectionsSessionManifest.NextPane
    ) {
        FeedbackGeneratorAdapter.errorOccurred()
        FinancialConnectionsEvent
            .events(fromError: error)
            .forEach { event in
                delegate?.analyticsClient(self, didReceiveEvent: event)
            }

        var parameters: [String: Any] = [:]
        parameters["error"] = errorName
        if let stripeError = error as? StripeError,
            case .apiError(let apiError) = stripeError
        {
            parameters["error_type"] = apiError.type.rawValue
            parameters["error_message"] = apiError.message
            parameters["code"] = apiError.code
        } else {
            parameters["error_type"] = (error as NSError).domain
            parameters["error_message"] = {
                if let sheetError = error as? FinancialConnectionsSheetError {
                    switch sheetError {
                    case .unknown(let debugDescription):
                        return debugDescription
                    }
                } else {
                    return (error as NSError).localizedDescription
                }
            }() as String
            parameters["code"] = (error as NSError).code
        }
        log(eventName: eventName, parameters: parameters, pane: pane)
    }

    func logMerchantDataAccessLearnMore(pane: FinancialConnectionsSessionManifest.NextPane) {
        log(
            eventName: "click.data_access.learn_more",
            pane: pane
        )
    }

    func setAdditionalParameters(
        publishableKey: String?,
        stripeAccount: String?
    ) {
        additionalParameters["key"] = publishableKey
        additionalParameters["stripe_account"] = stripeAccount
    }

    func setAdditionalParameters(fromManifest manifest: FinancialConnectionsSessionManifest) {
        additionalParameters["las_id"] = manifest.id
        additionalParameters["livemode"] = manifest.livemode
        additionalParameters["product"] = manifest.product
        additionalParameters["is_stripe_direct"] = manifest.isStripeDirect
        additionalParameters["single_account"] = manifest.singleAccount
        additionalParameters["allow_manual_entry"] = manifest.allowManualEntry
        additionalParameters["account_holder_id"] = manifest.accountholderToken
        additionalParameters["app_verification_enabled"] = manifest.appVerificationEnabled
    }

    static func paneFromViewController(
        _ viewController: UIViewController?
    ) -> FinancialConnectionsSessionManifest.NextPane {
        switch viewController {
        case is ConsentViewController:
            return .consent
        case is IDConsentContentViewController:
            return .idConsentContent
        case is InstitutionPickerViewController:
            return .institutionPicker
        case let partnerAuthViewController as PartnerAuthViewController:
            return partnerAuthViewController.pane
        case is AccountPickerViewController:
            return .accountPicker
        case is AttachLinkedPaymentAccountViewController:
            return .attachLinkedPaymentAccount
        case is SuccessViewController:
            return .success
        case is ManualEntryViewController:
            return .manualEntry
        case is ResetFlowViewController:
            return .resetFlow
        case is TerminalErrorViewController:
            return .terminalError
        case is NetworkingLinkSignupViewController:
            return .networkingLinkSignupPane
        case is NetworkingLinkLoginWarmupViewController:
            return .networkingLinkLoginWarmup
        case is NetworkingLinkVerificationViewController:
            return .networkingLinkVerification
        case is NetworkingLinkStepUpVerificationViewController:
            return .networkingLinkStepUpVerification
        case is NetworkingSaveToLinkVerificationViewController:
            return .networkingSaveToLinkVerification
        case is LinkAccountPickerViewController:
            return .linkAccountPicker
        case is LinkLoginViewController:
            return .linkLogin
        case is ErrorViewController:
            return .unexpectedError
        default:
            return .unparsable
        }
    }
}
