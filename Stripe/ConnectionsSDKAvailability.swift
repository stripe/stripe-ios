//
//  FinancialConnectionsSDKAvailability.swift
//  StripeiOS
//
//  Created by Vardges Avetisyan on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@available(iOS 12, *)
struct FinancialConnectionsSDKAvailability {
    static let FinancialConnectionsSDKClass: FinancialConnectionsSDKInterface.Type? = NSClassFromString("StripeFinancialConnections.FinancialConnectionsSDKImplementation") as? FinancialConnectionsSDKInterface.Type

    static let isUnitTest: Bool = NSClassFromString("XCTest") != nil

    static var isFinancialConnectionsSDKAvailable: Bool {
        // return true for tests
        if isUnitTest {
            return true
        }
        return FinancialConnectionsSDKClass != nil
    }

    static func financialConnections() -> FinancialConnectionsSDKInterface? {
        guard let klass = FinancialConnectionsSDKClass else {
            return nil
        }

        return klass.init()
    }
}
