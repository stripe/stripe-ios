//
//  FinancialConnectionsSDKAvailability.swift
//  StripeiOS
//
//  Created by Vardges Avetisyan on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
import SwiftUI

@available(iOS 12, *)
struct FinancialConnectionsSDKAvailability {
    static let FinancialConnectionsSDKClass: FinancialConnectionsSDKInterface.Type? = NSClassFromString("StripeFinancialConnections.FinancialConnectionsSDKImplementation") as? FinancialConnectionsSDKInterface.Type

    static let isUnitOrUITest: Bool = {
#if targetEnvironment(simulator)
        return NSClassFromString("XCTest") != nil || ProcessInfo.processInfo.environment["UITesting"] != nil
#else
        return false
#endif
    }()

    static var isFinancialConnectionsSDKAvailable: Bool {
        // return true for tests
        if isUnitOrUITest {
            return true
        }
        return FinancialConnectionsSDKClass != nil
    }

    static func financialConnections() -> FinancialConnectionsSDKInterface? {
        if isUnitOrUITest {
            return StubbedConnectionsSDKInterface()
        }

        guard let klass = FinancialConnectionsSDKClass else {
            return nil
        }

        return klass.init()
    }
}

final class StubbedConnectionsSDKInterface: FinancialConnectionsSDKInterface {
    func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> ()
    ) {
        DispatchQueue.main.async {
            completion(FinancialConnectionsSDKResult.completed(linkedBank: StubbedLinkedBank()))
        }
    }
}

struct StubbedLinkedBank: LinkedBank {
    var sessionId: String = "las_123"

    var accountId: String = "fca_123"

    var displayName: String? = "Test Bank"

    var bankName: String? = "Test Bank"

    var last4: String? = "1234"

    var instantlyVerified: Bool = true
}
