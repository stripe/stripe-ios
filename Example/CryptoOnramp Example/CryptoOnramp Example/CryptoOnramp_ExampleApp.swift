//
//  CryptoOnramp_ExampleApp.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import SwiftUI
import UIKit

/// The root of the example CryptoOnramp app.
@main
struct CryptoOnramp_ExampleApp: App {
    @State private var isLoading: Bool = false

    init() {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.environment["UITesting"] != nil {
            // Disable hardware keyboards to make simulator text entry more reliable in UI tests.
            let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
            UITextInputMode.activeInputModes
                .filter { $0.responds(to: setHardwareLayout) }
                .forEach { $0.perform(setHardwareLayout, with: nil) }
        }
        #endif
    }

    // MARK: - App

    var body: some Scene {
        WindowGroup {
            CryptoOnrampExampleView()
                .environment(\.isLoading, $isLoading)
                .loadingOverlay(isVisible: isLoading)
        }
    }
}
