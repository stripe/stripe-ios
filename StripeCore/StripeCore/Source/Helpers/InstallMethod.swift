//
//  InstallMethod.swift
//  StripeCore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

enum InstallMethod: String {
    case cocoapods = "C"
    case spm = "S"
    case binary = "B"  // Built via export_builds.sh
    case xcode = "X"  // Directly built via Xcode or xcodebuild

    static let current: InstallMethod = {
        #if COCOAPODS
            return .cocoapods
        #elseif SWIFT_PACKAGE
            return .spm
        #elseif STRIPE_BUILD_PACKAGE
            return .binary
        #else
            return .xcode
        #endif
    }()
}
