//
//  PresentationManager.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2025-01-30.
//

@_spi(STP) import StripeCore
import UIKit

/// Handles applying the current style configuration to each view controller presented.
class PresentationManager {
    static let shared = PresentationManager()

    var configuration: FinancialConnectionsSheet.Configuration = .init()
    var consumerLinkBrand: LinkBrand?

    func resolvedLinkBrand(manifestLinkBrand: LinkBrand?) -> LinkBrand? {
        switch configuration.linkBrand {
        case .link:
            return .link
        case .onelink:
            return .onelink
        case .unparsable, .none:
            break
        }

        switch consumerLinkBrand {
        case .link:
            return .link
        case .onelink:
            return .onelink
        case .unparsable, .none:
            break
        }

        switch manifestLinkBrand {
        case .link:
            return .link
        case .onelink:
            return .onelink
        case .unparsable, .none:
            return nil
        }
    }

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
