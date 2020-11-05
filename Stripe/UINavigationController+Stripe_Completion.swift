//
//  UINavigationController+Stripe_Completion.swift
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

// See http://stackoverflow.com/questions/9906966/completion-handler-for-uinavigationcontroller-pushviewcontrolleranimated/33767837#33767837 for some discussion around why using CATransaction is unreliable here.

extension UINavigationController {
  func stp_push(
    _ viewController: UIViewController?,
    animated: Bool,
    completion: @escaping STPVoidBlock
  ) {
    if let viewController = viewController {
      pushViewController(viewController, animated: animated)
    }
    if transitionCoordinator != nil && animated {
      transitionCoordinator?.animate(alongsideTransition: nil) { _ in
        completion()
      }
    } else {
      completion()
    }
  }

  func stp_popViewController(
    animated: Bool,
    completion: @escaping STPVoidBlock
  ) {
    popViewController(animated: animated)
    if transitionCoordinator != nil && animated {
      transitionCoordinator?.animate(alongsideTransition: nil) { _ in
        completion()
      }
    } else {
      completion()
    }
  }

  @objc(stp_popToViewController:animated:completion:) func stp_pop(
    to viewController: UIViewController?,
    animated: Bool,
    completion: @escaping STPVoidBlock
  ) {
    if let viewController = viewController {
      popToViewController(viewController, animated: animated)
    }
    if transitionCoordinator != nil && animated {
      transitionCoordinator?.animate(alongsideTransition: nil) { _ in
        completion()
      }
    } else {
      completion()
    }
  }
}
