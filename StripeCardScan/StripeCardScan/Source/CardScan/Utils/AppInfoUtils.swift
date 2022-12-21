//
//  AppInfoUtils.swift
//  CardScan
//
//  Created by Jaime Park on 4/15/21.
//

import Foundation

struct AppInfoUtils {
    static let appPackageName: String? = getAppPackageName()
    static let applicationId: String? = nil
    static let libraryPackageName: String? = getLibraryPackageName()
    static let sdkVersion: String = getSdkVersion()
    static let sdkVersionCode: Int? = nil
    static let sdkFlavor: String? = nil
    static let isDebugBuild: Bool = getIsDebugBuild()

    static func getAppPackageName() -> String {
        return Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "unknown"
    }

    static func getLibraryPackageName() -> String? {
        return Bundle.main.bundleIdentifier
    }

    static func getSdkVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"].flatMap { $0 as? String }
            ?? "unknown"
    }

    static func getBuildVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"].flatMap { $0 as? String } ?? "unknown"
    }

    static func getIsDebugBuild() -> Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}
