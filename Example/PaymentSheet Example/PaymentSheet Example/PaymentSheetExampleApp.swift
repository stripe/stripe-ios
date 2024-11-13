//
//  PaymentSheetExampleApp.swift
//  PaymentSheet Example
//
//  Created by David Estes on 11/8/24.
//

import Foundation
import SwiftUI

@main
struct MyExampleApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    var body: some Scene {
        WindowGroup {
            PaymentSheetTestPlayground(settings: PlaygroundController.settingsFromDefaults() ?? .defaultValues())
        }
    }
}
