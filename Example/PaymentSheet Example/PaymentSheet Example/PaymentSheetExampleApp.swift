//
//  PaymentSheetExampleApp.swift
//  PaymentSheet Example
//

import SwiftUI

@available(iOS 15.0, *)
@main
struct PaymentSheetExampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appdelegate
    var body: some Scene {
        WindowGroup {
            if #available(iOS 14.0, *) {
                DesignCanvas()
            } else {
                PaymentSheetExampleAppRootView()
            }
        }
    }
}
