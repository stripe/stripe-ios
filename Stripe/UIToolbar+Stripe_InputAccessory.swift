//
//  UIToolbar+Stripe_InputAccessory.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/22/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIToolbar {
  @objc(stp_inputAccessoryToolbarWithTarget:action:) class func stp_inputAccessoryToolbar(
    withTarget target: Any?, action: Selector
  ) -> Self {
    let toolbar = self.init()
    let flexibleItem = UIBarButtonItem(
      barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let nextItem = UIBarButtonItem(
      title: STPLocalizedString("Next", "Button to move to the next text entry field"),
      style: .done, target: target, action: action)
    toolbar.items = [flexibleItem, nextItem]
    toolbar.autoresizingMask = .flexibleHeight
    return toolbar
  }

  @objc(stp_setEnabled:) func stp_setEnabled(_ enabled: Bool) {
    for barButtonItem in items ?? [] {
      barButtonItem.isEnabled = enabled
    }
  }
}
