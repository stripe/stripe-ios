//
//  UIViewController+Stripe_NavigationItemProxy.swift
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import ObjectiveC
import UIKit

extension UIViewController {
  @objc var stp_navigationItemProxy: UINavigationItem? {
    get {
      return objc_getAssociatedObject(self, UnsafeRawPointer(&kSTPNavigationItemProxyKey))
        as? UINavigationItem ?? self.navigationItem
    }
    set(stp_navigationItemProxy) {
      objc_setAssociatedObject(
        self, UnsafeRawPointer(&kSTPNavigationItemProxyKey), stp_navigationItemProxy,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      if navigationItem.leftBarButtonItem != nil {
        stp_navigationItemProxy?.leftBarButtonItem = navigationItem.leftBarButtonItem
      }
      if navigationItem.rightBarButtonItem != nil {
        stp_navigationItemProxy?.rightBarButtonItem = navigationItem.rightBarButtonItem
      }
      if navigationItem.title != nil {
        stp_navigationItemProxy?.title = navigationItem.title
      }
    }
  }
}

private var kSTPNavigationItemProxyKey = 0
