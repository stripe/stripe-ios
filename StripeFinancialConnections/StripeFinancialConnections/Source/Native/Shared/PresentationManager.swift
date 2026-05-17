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
    static let linkBrandDidChangeNotification = Notification.Name("com.stripe.financialconnections.linkBrandDidChange")

    var configuration: FinancialConnectionsSheet.Configuration = .init()
    var consumerLinkBrand: LinkBrand? {
        didSet {
            guard consumerLinkBrand != oldValue else { return }
            NotificationCenter.default.post(name: Self.linkBrandDidChangeNotification, object: nil)
        }
    }

    /// Updates `consumerLinkBrand` from a consumer session, but only when the session is
    /// verified and carries a non-nil brand. Unverified sessions (e.g. from
    /// `startVerificationSession`) must not clear a brand set by a prior `confirm_verification`.
    func setConsumerLinkBrand(from consumerSession: ConsumerSessionData?) {
        guard consumerSession?.isVerified == true, let brand = consumerSession?.linkBrand else {
            return
        }
        consumerLinkBrand = brand
    }

    /// Explicitly resets the consumer brand. Call this at the start of a new FC session so
    /// a stale brand from a previous presentation does not bleed in.
    func resetConsumerLinkBrand() {
        consumerLinkBrand = nil
    }

    func resolvedLinkBrand(manifestLinkBrand: LinkBrand?) -> LinkBrand? {
        switch consumerLinkBrand {
        case .link:
            return .link
        case .onelink:
            return .onelink
        case .unparsable, .none:
            break
        }

        switch configuration.linkBrand {
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
