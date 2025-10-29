//
//  UIApplication+CryptoOnramp.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI
import UIKit

extension UIApplication {

    private var rootViewController: UIViewController? {
        (connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController
    }

    /// Attempts to locate the topmost navigation controller for direct manipulation within a primarily-SwiftUI context.
    /// - Returns: The topmost navigation controller, or `nil` if not found.
    func findTopNavigationController() -> UINavigationController? {
        guard let rootViewController else {
            return nil
        }

        return findNavigationController(in: rootViewController)
    }

    /// Finds the top view controller, regardless of its type.
    /// - Parameter baseViewController: The base view controller from which to start searching. Specify `nil` to start at the root.
    /// - Returns: The topmost view controller.
    func findTopViewController(baseViewController: UIViewController? = nil) -> UIViewController? {
        let baseViewController = baseViewController ?? rootViewController

        if let navigationController = baseViewController as? UINavigationController {
            return findTopViewController(baseViewController: navigationController.visibleViewController)
        } else if let tabBarController = baseViewController as? UITabBarController {
            return findTopViewController(baseViewController: tabBarController.selectedViewController)
        } else if let presentedViewController = baseViewController?.presentedViewController {
            return findTopViewController(baseViewController: presentedViewController)
        } else {
            return baseViewController
        }
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
