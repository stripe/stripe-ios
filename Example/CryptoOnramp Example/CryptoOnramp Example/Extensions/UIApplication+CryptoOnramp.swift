//
//  UIApplication+CryptoOnramp.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI
import UIKit

extension UIApplication {

    /// Attempts to locate the topmost navigation controller for direct manipulation within a primarily-SwiftUI context.
    /// - Returns: The topmost navigation controller, or `nil` if not found.
    func findTopNavigationController() -> UINavigationController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }

        return findNavigationController(in: window.rootViewController)
    }

    private func findNavigationController(in viewController: UIViewController?) -> UINavigationController? {
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }

        if let presentedViewController = viewController?.presentedViewController {
            return findNavigationController(in: presentedViewController)
        }

        for child in viewController?.children ?? [] {
            if let found = findNavigationController(in: child) {
                return found
            }
        }

        return nil
    }
}
