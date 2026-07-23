//
//  PaymentSheetExampleApp.swift
//  PaymentSheet Example
//

import SwiftUI

@main
struct PaymentSheetExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appdelegate
    var body: some Scene {
        WindowGroup {
            PaymentSheetExampleAppRootView()
        }
    }
}
