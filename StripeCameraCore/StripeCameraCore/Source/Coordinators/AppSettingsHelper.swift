//
//  AppSettingsHelper.swift
//  StripeCameraCore
//
//  Created by Mel Ludowise on 12/3/21.
//

import Foundation
import UIKit

public protocol AppSettingsHelperProtocol {
    var canOpenAppSettings: Bool { get }
    func openAppSettings()
}

/// Helper class that opens the app's settings screen in the Settings app.
@available(iOSApplicationExtension, unavailable)
@_spi(STP) public class AppSettingsHelper: AppSettingsHelperProtocol {

    public static let shared = AppSettingsHelper()

    private(set) lazy var appSettingsUrl: URL? = URL(string: UIApplication.openSettingsURLString)

    private init() {
        // Use shared instance instead of init
    }

    /// `true` if the system is able to open the app's settings screen.
    public var canOpenAppSettings: Bool {
        guard let settingsUrl = appSettingsUrl else {
            return false
        }
        return UIApplication.shared.canOpenURL(settingsUrl)
    }

    /// Opens the app's settings screen, if possible.
    public func openAppSettings() {
        guard let settingsUrl = appSettingsUrl else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}
