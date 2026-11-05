//
//  STPAuthenticationContext.swift
//  StripePayments
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
import UIKit

/// `STPAuthenticationContext` provides information required to present authentication challenges
/// to a user.
public protocol STPAuthenticationContext: AnyObject {
    /// The Stripe SDK will modally present additional view controllers on top
    /// of the `authenticationPresentingViewController` when required for user
    /// authentication, like in the Challenge Flow for 3DS2 transactions.
    @MainActor @preconcurrency
    func authenticationPresentingViewController() -> UIViewController

    /// This method is called before presenting a UIViewController for authentication.
    /// The default implementation calls `completion` immediately.
    /// @note `STPPaymentHandler` will not proceed until `completion` is called.
    @MainActor @preconcurrency
    func prepare(forPresentation completion: @escaping STPVoidBlock)

    /// This method is called before presenting an SFSafariViewController for web-based authentication.
    /// Implement this method to configure the `SFSafariViewController` instance, e.g. `viewController.preferredBarTintColor = MyBarTintColor`
    /// The default implementation does nothing.
    /// @note Setting the `delegate` property has no effect.
    @MainActor @preconcurrency
    func configureSafariViewController(_ viewController: SFSafariViewController)

    /// This method is called when an authentication UIViewController is about to be dismissed.
    /// Implement this method to prepare your UI for the authentication view controller to be dismissed. For example,
    /// if you requested authentication while displaying an STPBankSelectionViewController, you may want to hide
    /// it to return the user to your desired view controller.
    /// The default implementation does nothing.
    @MainActor @preconcurrency
    func authenticationContextWillDismiss(_ viewController: UIViewController)
}

extension STPAuthenticationContext {
    /// :nodoc:
    @MainActor @preconcurrency
    public func prepare(forPresentation completion: @escaping STPVoidBlock) {
        completion()
    }

    /// :nodoc:
    @MainActor @preconcurrency
    public func configureSafariViewController(_ viewController: SFSafariViewController) {}

    /// :nodoc:
    @MainActor @preconcurrency
    public func authenticationContextWillDismiss(_ viewController: UIViewController) {}
}

/// An `STPAuthenticationContext` that is notified after an authentication UIViewController has been dismissed.
/// :nodoc:
@_spi(InternalOnlyAPI) public protocol _stpinternal_STPAuthenticationContextDismissalObserver: STPAuthenticationContext {
    /// This method is called when an authentication UIViewController has been dismissed.
    /// Implement this method to have your UI respond to the authentication view controller to being dismissed. For example,
    /// if you requested authentication while displaying an STPBankSelectionViewController, you may want to hide
    /// it to return the user to your desired view controller.
    func authenticationContextDidDismiss(_ viewController: UIViewController)
}
