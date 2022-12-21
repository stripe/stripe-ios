//
//  PluginDetector.swift
//  StripeCore
//
//  Created by Nick Porter on 10/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// A class which can detect if the host app is using a known cross-platform solution.
class PluginDetector {

    /// Shared instance of the `PluginDetector` to enable caching of the `pluginType`.
    static let shared = PluginDetector()

    /// Represents all the known/tracked cross-platform solutions.
    enum PluginType: String, CaseIterable {
        case cordova
        case flutter
        case ionic
        case reactNative = "react-native"
        case unity
        case xamarin

        /// Represents a known class contained in each cross-platform environment.
        var className: String {
            switch self {
            case .cordova: return "CDVPlugin"
            case .flutter: return "FlutterAppDelegate"
            case .ionic: return "CAPPlugin"
            case .reactNative: return "RCTBridge"
            case .unity: return "UnityFramework"
            case .xamarin: return "XamarinAssociatedObject"
            }
        }
    }

    /// Determines if this app is running within a plugin environment.
    ///
    /// - Returns: returns the plugin type if found, otherwise nil.
    lazy var pluginType: PluginType? = {
        PluginType.allCases.first { type in
            NSClassFromString(type.className) != nil
        }
    }()
}
