//
//  PaymentSheetExampleApp.swift
//  PaymentSheet Example
//

import SwiftUI

@available(iOS 14.0, *)
@main
struct PaymentSheetExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appdelegate
    var body: some Scene {
        WindowGroup {
            PaymentSheetExampleAppRootView()
        }
    }
}
