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
    
    static func getAppPackageName() -> String? {
        return Bundle.main.bundleIdentifier
    }

    static func getLibraryPackageName() -> String? {
        if #available(iOS 11.2, *) {
            return CSBundle.bundleIdentifier
        } else {
            return nil
        }
    }
    
    static func getSdkVersion() -> String {
        guard let bundle = CSBundle.bundle() else {
            return "unknown"
        }
        
        return bundle.infoDictionary?["CFBundleShortVersionString"].flatMap { $0 as? String } ?? "unknown"
    }
    
    static func getIsDebugBuild() -> Bool {
        #if DEBUG
            return true
        #else
           return false
        #endif
    }
}
