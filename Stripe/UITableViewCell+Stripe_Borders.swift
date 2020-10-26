//
//  UITableViewCell+Stripe_Borders.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

private let STPTableViewCellTopBorderTag = 787473
private let STPTableViewCellBottomBorderTag = 787474
private let STPTableViewCellFakeSeparatorTag = 787475

extension UITableViewCell {
  @objc(stp_setBorderColor:) func stp_setBorderColor(_ color: UIColor?) {
    stp_topBorderView()?.backgroundColor = color
    stp_bottomBorderView()?.backgroundColor = color
  }

  @objc(stp_setTopBorderHidden:) func stp_setTopBorderHidden(_ hidden: Bool) {
    stp_topBorderView()?.isHidden = hidden
  }

  @objc(stp_setBottomBorderHidden:) func stp_setBottomBorderHidden(_ hidden: Bool) {
    stp_bottomBorderView()?.isHidden = hidden
    stp_fakeSeparatorView()?.isHidden = !hidden
  }

  @objc(stp_setFakeSeparatorLeftInset:) func stp_setFakeSeparatorLeftInset(_ leftInset: CGFloat) {
    stp_fakeSeparatorView()?.frame = CGRect(
      x: leftInset, y: bounds.size.height - 0.5, width: bounds.size.width - leftInset, height: 0.5)
  }

  @objc(stp_setFakeSeparatorColor:) func stp_setFakeSeparatorColor(_ color: UIColor?) {
    stp_fakeSeparatorView()?.backgroundColor = color
  }

  func stp_topBorderView() -> UIView? {
    var view = viewWithTag(STPTableViewCellTopBorderTag)
    if view == nil {
      view = UIView(frame: CGRect(x: 0, y: 0, width: bounds.size.width, height: 0.5))
      view?.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
      view?.tag = STPTableViewCellTopBorderTag
      view?.backgroundColor = backgroundColor
      view?.isHidden = true
      view?.accessibilityIdentifier = "stp_topBorderView"
      if let view = view {
        addSubview(view)
      }
    }
    return view
  }

  func stp_bottomBorderView() -> UIView? {
    var view = viewWithTag(STPTableViewCellBottomBorderTag)
    if view == nil {
      view = UIView(
        frame: CGRect(x: 0, y: bounds.size.height - 0.5, width: bounds.size.width, height: 0.5))
      view?.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
      view?.tag = STPTableViewCellBottomBorderTag
      view?.backgroundColor = backgroundColor
      view?.isHidden = true
      view?.accessibilityIdentifier = "stp_bottomBorderView"
      if let view = view {
        addSubview(view)
      }
    }
    return view
  }

  func stp_fakeSeparatorView() -> UIView? {
    var view = viewWithTag(STPTableViewCellFakeSeparatorTag)
    if view == nil {
      view = UIView(
        frame: CGRect(x: 0, y: bounds.size.height - 0.5, width: bounds.size.width, height: 0.5))
      view?.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
      view?.tag = STPTableViewCellFakeSeparatorTag
      view?.backgroundColor = backgroundColor
      view?.accessibilityIdentifier = "stp_fakeSeparatorView"
      if let view = view {
        addSubview(view)
      }
    }
    return view
  }
}
