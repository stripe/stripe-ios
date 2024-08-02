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

    init(nextPaneOrDrawerOnSecondaryCta: String? = nil) {
        self.nextPaneOrDrawerOnSecondaryCta = nextPaneOrDrawerOnSecondaryCta
    }
}
