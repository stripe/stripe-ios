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
    static func connections() -> ConnectionsSDKInterface? {
        guard let klass = NSClassFromString("StripeConnections.ConnectionsSDKImplementation") as? ConnectionsSDKInterface.Type else {
            return nil
        }

        return klass.init()
    }
}
