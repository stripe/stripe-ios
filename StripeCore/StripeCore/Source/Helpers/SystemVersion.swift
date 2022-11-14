//
//  SystemInformation.swift
//  StripeCore
//
//  Created by David Estes on 11/4/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

import UIKit
#if os(watchOS)
import WatchKit
#endif

@_spi(STP) public class SystemInformation {
    static let version: String = {
#if os(iOS)
        return UIDevice.current.systemVersion
#elseif os(watchOS)
        return "Watch" + WKInterfaceDevice.current().systemVersion
#endif
    }()
    
    static let localizedModel: String = {
#if os(iOS)
        return UIDevice.current.localizedModel
#elseif os(watchOS)
        return WKInterfaceDevice.current().localizedModel
#endif
    }()
    
    static let identifierForVendor: UUID? = {
#if os(iOS)
        return UIDevice.current.identifierForVendor
#elseif os(watchOS)
        return WKInterfaceDevice.current().identifierForVendor
#endif
    }()
}
