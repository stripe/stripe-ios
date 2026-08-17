//
//  CreatePaneParameters.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/22/24.
//

import Foundation

// A bag of extra parameters we can pass to `CreatePaneViewController` function
// that creates new pane view controllers. This avoids preserving state in
// `NativeFlowDataManager` where the state might be outdated after a specific
// pane push.
struct CreatePaneParameters {
    let nextPaneOrDrawerOnSecondaryCta: String?
    let genericErrorPane: FinancialConnectionsGenericErrorPane?
    // Skips the prepane and opens the institution's OAuth flow as soon as the
    // auth session is created.
    let autoLaunchAuthSession: Bool

    init(
        nextPaneOrDrawerOnSecondaryCta: String? = nil,
        genericErrorPane: FinancialConnectionsGenericErrorPane? = nil,
        autoLaunchAuthSession: Bool = false
    ) {
        self.nextPaneOrDrawerOnSecondaryCta = nextPaneOrDrawerOnSecondaryCta
        self.genericErrorPane = genericErrorPane
        self.autoLaunchAuthSession = autoLaunchAuthSession
    }
}
