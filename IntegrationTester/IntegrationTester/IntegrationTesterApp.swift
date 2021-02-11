//
//  IntegrationTesterApp.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import SwiftUI
import Stripe

@main
struct IntegrationTesterApp: App {
    var body: some Scene {
        WindowGroup {
            MainMenu()
                .onOpenURL { url in
                    StripeAPI.handleURLCallback(with: url)
                }
        }
    }
}
