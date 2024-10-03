//
//  ConnectionsSDKAvailability.swift
//  StripePayments
//
//  Created by Vardges Avetisyan on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
import SwiftUI
import UIKit

@_spi(STP) public struct FinancialConnectionsSDKAvailability {
    static let FinancialConnectionsSDKClass: FinancialConnectionsSDKInterface.Type? =
        NSClassFromString("StripeFinancialConnections.FinancialConnectionsSDKImplementation")
        as? FinancialConnectionsSDKInterface.Type

    static let isUnitOrUITest: Bool = {
        #if targetEnvironment(simulator)
        let useProductionSDK = ProcessInfo.processInfo.environment["USE_PRODUCTION_FINANCIAL_CONNECTIONS_SDK"] == "true"
        return !useProductionSDK && (NSClassFromString("XCTest") != nil || ProcessInfo.processInfo.environment["UITesting"] != nil)
        #else
            return false
        #endif
    }()

    @_spi(STP) public static var isFinancialConnectionsSDKAvailable: Bool {
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
        elementsSessionContext: ElementsSessionContext?,
        onEvent: ((FinancialConnectionsEvent) -> Void)?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        DispatchQueue.main.async {
            let stubbedBank = FinancialConnectionsLinkedBank(
                sessionId: "las_123",
                accountId: "fca_123",
                displayName: "Test Bank",
                bankName: "Test Bank",
                last4: "1234",
                instantlyVerified: true
            )
            completion(
                FinancialConnectionsSDKResult.completed(
                    .financialConnections(stubbedBank)
                )
            )
        }
    }
}
