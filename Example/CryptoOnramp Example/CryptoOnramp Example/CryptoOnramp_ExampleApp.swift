//
//  CryptoOnramp_ExampleApp.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/24/25.
//

import SwiftUI

@main
struct CryptoOnramp_ExampleApp: App {
    @State private var isLoading: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                CryptoOnrampExampleView()
                    .environment(\.isLoading, $isLoading)

                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Loading…")
                }
            }
        }
    }
}
