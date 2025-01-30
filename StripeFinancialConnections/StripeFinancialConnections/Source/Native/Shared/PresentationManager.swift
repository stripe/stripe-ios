//
//  PresentationManager.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-30.
//

import UIKit

/// Handles applying the current style configuration to each view controller presented.
class PresentationManager {
    static let shared = PresentationManager()

    var configuration: FinancialConnectionsSheet.Configuration = .init()

    func present(
        _ viewControllerToPresent: UIViewController,
        from presentingViewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        configuration.style.configure(viewControllerToPresent)
        presentingViewController.present(viewControllerToPresent, animated: animated, completion: completion)
    }
}
