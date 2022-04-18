//
//  ConnectionsSDKAvailability.swift
//  StripeiOS
//
//  Created by Vardges Avetisyan on 2/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@available(iOS 12, *)
struct ConnectionsSDKAvailability {
    static let ConnectionsSDKClass: ConnectionsSDKInterface.Type? = NSClassFromString("StripeConnections.ConnectionsSDKImplementation") as? ConnectionsSDKInterface.Type

    static let isUnitTest: Bool = NSClassFromString("XCTest") != nil

    static var isConnectionsSDKAvailable: Bool {
        // return true for tests
        if isUnitTest {
            return true
        }
        return ConnectionsSDKClass != nil
    }

    static func connections() -> ConnectionsSDKInterface? {
        guard let klass = ConnectionsSDKClass else {
            return nil
        }

        return klass.init()
    }
}
