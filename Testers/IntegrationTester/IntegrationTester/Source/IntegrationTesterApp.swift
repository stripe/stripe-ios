//
//  IntegrationTesterApp.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import Stripe
import SwiftUI

@main
struct IntegrationTesterApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenu()
              .onOpenURL { url in
                  StripeAPI.handleURLCallback(with: url)
              }
              .onAppear {
                // As early as possible, configure STPAPIClient with your publishable key.
                BackendModel.shared.loadPublishableKey { publishableKey in
                  STPAPIClient.shared.publishableKey = publishableKey
                }

                // Disable hardware keyboards in CI:
                #if targetEnvironment(simulator)
                if ProcessInfo.processInfo.environment["UITesting"] != nil {
                    let setHardwareLayout = NSSelectorFromString("setHardwareLayout:")
                    UITextInputMode.activeInputModes
                        .filter({ $0.responds(to: setHardwareLayout) })
                        .forEach { $0.perform(setHardwareLayout, with: nil) }
                }
                #endif
              }
        }
    }
}
