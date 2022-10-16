//
//  FinancialConnectionsAnalyticsClient.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/13/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

final class FinancialConnectionsAnalyticsClient {
    
    private let analyticsClient: AnalyticsClientV2
    private var additionalParameters: [String:Any] = [:]
    
    init(analyticsClient: AnalyticsClientV2 = AnalyticsClientV2(clientId: "", origin: "")) {
        self.analyticsClient = analyticsClient
    }
    
    public func log(eventName: String, parameters: [String: Any] = [:]) {
        let parameters = parameters.merging(
            additionalParameters,
            uniquingKeysWith: { eventParameter, _ in
                // prioritize event `parameters` over `additionalParameters`
                return eventParameter
            }
        )
        
        // TODO(kgaidis): uncomment when we are ready to fire events
        print("^ logging event: ", eventName, parameters)
        // analyticsClient.log(eventName: eventName, parameters: parameters)
    }
}

extension FinancialConnectionsAnalyticsClient {
    
    func setAdditionalParameters(fromManifest manifest: FinancialConnectionsSessionManifest) {
        // TODO(kgaidis): discuss with others on the need for the other events
        
//        additionalParameters["hostname"] = document.location.hostname
//        additionalParameters["las_client_secret"] = this.linkAccountSessionClientSecret
//        additionalParameters["las_creator_client_secret"] = this.linkAccountSessionCreatorClientSecret
//        additionalParameters["las_creator_type"] = this.linkAccountSessionCreatorType
//        additionalParameters["las_creator_id"] = this.linkAccountSessionCreatorId

//        additionalParameters["key"] = this.apiKey
//        additionalParameters["stripe_account"] = this.stripeAccount
//        additionalParameters["logger_id"] = this.getLoggerId(),
//        additionalParameters["navigator_language"] = navigatorLanguage(),
//        additionalParameters["is_webview"] = isWebView(window.navigator.userAgent)
        
        additionalParameters["livemode"] = manifest.livemode
        additionalParameters["product"] = manifest.product
        additionalParameters["is_stripe_direct"] = manifest.isStripeDirect
        additionalParameters["single_account"] = manifest.singleAccount
        additionalParameters["allow_manual_entry"] = manifest.singleAccount
        additionalParameters["account_holder_id"] = manifest.accountholderToken
    }
}


extension FinancialConnectionsAnalyticsClient {
    
    @available(iOSApplicationExtension, unavailable)
    static func paneFromViewController(
        _ viewController: UIViewController?
    ) -> FinancialConnectionsSessionManifest.NextPane {
        switch viewController {
        case is ConsentViewController:
            return .consent
        case is InstitutionPicker:
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
