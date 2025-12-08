//
//  FCLiteWebFlowResult.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-11-20.
//

import Foundation

enum FCLiteWebFlowResult {
    enum CancellationType {
        case cancelledWithinWebview
        case cancelledOutsideWebView
    }

    case success(returnUrl: URL)
    case cancelled(CancellationType)
    case failure(Error)
    case redirect(url: URL)
}
