//
//  STPDeviceUtils.swift
//  StripeCore
//
//  Created by Mel Ludowise on 3/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

struct STPDeviceUtils {
    static var deviceType: String? {
        var systemInfo: utsname = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceType = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        guard !deviceType.isEmpty else {
            return nil
        }
        return deviceType
    }
}
