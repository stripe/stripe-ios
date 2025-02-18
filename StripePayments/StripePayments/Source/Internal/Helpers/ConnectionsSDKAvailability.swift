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

    static let isUnitTest: Bool = {
        #if targetEnvironment(simulator)
        return NSClassFromString("XCTest") != nil
        #else
            return false
        #endif
    }()

    static let isUITest: Bool = {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["UITesting"] != nil
        #else
            return false
        #endif
    }()

    // Return true for unit tests, the value of `FinancialConnectionsSDKAvailable` for UI tests,
    // and whether or not the Financial Connections SDK is available otherwise.
    @_spi(STP) public static var isFinancialConnectionsSDKAvailable: Bool {
        if isUnitTest {
            return true
        } else if isUITest {
            let financialConnectionsSDKAvailable = ProcessInfo.processInfo.environment["FinancialConnectionsSDKAvailable"] == "true"
            return financialConnectionsSDKAvailable
        } else {
            return FinancialConnectionsSDKClass != nil
        }
    }

    static func financialConnections() -> FinancialConnectionsSDKInterface? {
        let financialConnectionsStubbedResult = ProcessInfo.processInfo.environment["FinancialConnectionsStubbedResult"] == "true"
        if isUnitTest || (isUITest && financialConnectionsStubbedResult) {
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
        style: FinancialConnectionsStyle,
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
