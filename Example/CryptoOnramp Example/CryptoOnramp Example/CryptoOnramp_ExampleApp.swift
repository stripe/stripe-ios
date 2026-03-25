//
//  CryptoOnramp_ExampleApp.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import SwiftUI

/// The root of the example CryptoOnramp app.
@main
struct CryptoOnramp_ExampleApp: App {
    @State private var isLoading: Bool = false

    // MARK: - App

    var body: some Scene {
        WindowGroup {
            CryptoOnrampExampleView()
                .environment(\.isLoading, $isLoading)
                .loadingOverlay(isVisible: isLoading)
        }
    }
}
