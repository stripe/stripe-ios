//
//  STPAuthenticationContext.swift
//  Stripe
//
//  Created by Cameron Sabol on 5/10/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation
import SafariServices
import UIKit

/// `STPAuthenticationContext` provides information required to present authentication challenges
/// to a user.
@objc public protocol STPAuthenticationContext: NSObjectProtocol {
  /// The Stripe SDK will modally present additional view controllers on top
  /// of the `authenticationPresentingViewController` when required for user
  /// authentication, like in the Challenge Flow for 3DS2 transactions.
  func authenticationPresentingViewController() -> UIViewController

  /// This method is called before presenting a UIViewController for authentication.
  /// @note `STPPaymentHandler` will not proceed until `completion` is called.
  @objc(prepareAuthenticationContextForPresentation:) optional func prepare(
    forPresentation completion: @escaping STPVoidBlock)
  /// This method is called before presenting an SFSafariViewController for web-based authentication.
  /// Implement this method to configure the `SFSafariViewController` instance, e.g. `viewController.preferredBarTintColor = MyBarTintColor`
  /// @note Setting the `delegate` property has no effect.
  @objc optional func configureSafariViewController(_ viewController: SFSafariViewController)
  /// This method is called when an authentication UIViewController is about to be dismissed.
  /// Implement this method to prepare your UI for the authentication view controller to be dismissed. For example,
  /// if you requested authentication while displaying an STPBankSelectionViewController, you may want to hide
  /// it to return the user to your desired view controller.
  @objc(authenticationContextWillDismissViewController:)
  optional func authenticationContextWillDismiss(_ viewController: UIViewController)
}
