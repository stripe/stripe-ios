//
//  STPBankSelectionTableViewCell.swift
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import UIKit

class STPBankSelectionTableViewCell: UITableViewCell {
  func configure(
    withBank bankBrand: STPFPXBankBrand, theme: STPTheme, selected: Bool, offline: Bool,
    enabled: Bool
  ) {
    bank = bankBrand
    self.theme = theme

    backgroundColor = theme.secondaryBackgroundColor

    // Left icon
    leftIcon?.image = STPImageLibrary.fpxBrandImage(for: bank)
    leftIcon?.tintColor = primaryColorForPaymentOption(withSelected: selected, enabled: enabled)

    // Title label
    titleLabel?.font = theme.font
    titleLabel?.text = STPFPXBank.stringFrom(bank)
    if offline {
      let format = STPLocalizedString(
        "%@ - Offline", "Bank name when bank is offline for maintenance.")
      titleLabel?.text = String(format: format, STPFPXBank.stringFrom(bank) ?? "")
    }
    titleLabel?.textColor = primaryColorForPaymentOption(withSelected: isSelected, enabled: enabled)

    // Loading indicator
    activityIndicator?.tintColor = theme.accentColor
    if selected {
      activityIndicator?.startAnimating()
    } else {
      activityIndicator?.stopAnimating()
    }

    setNeedsLayout()
  }

  private var bank: STPFPXBankBrand!
  private var theme: STPTheme = .defaultTheme
  private var leftIcon: UIImageView?
  private var titleLabel: UILabel?
  private var activityIndicator: UIActivityIndicatorView?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    // Left icon
    let leftIcon = UIImageView()
    self.leftIcon = leftIcon
    contentView.addSubview(leftIcon)

    // Title label
    let titleLabel = UILabel()
    self.titleLabel = titleLabel
    contentView.addSubview(titleLabel)

    // Loading indicator
    var activityIndicator: UIActivityIndicatorView?
    if #available(iOS 13.0, *) {
      activityIndicator = UIActivityIndicatorView(style: .medium)
    } else {
      activityIndicator = UIActivityIndicatorView(style: .gray)
    }
    self.activityIndicator = activityIndicator
    self.activityIndicator?.hidesWhenStopped = true
    if let activityIndicator = activityIndicator {
      contentView.addSubview(activityIndicator)
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let midY = bounds.midY
    let padding: CGFloat = 15.0
    let iconWidth: CGFloat = 26.0

    // Left icon
    leftIcon?.sizeToFit()
    leftIcon?.center = CGPoint(x: padding + (iconWidth / 2.0), y: midY)

    // Activity indicator
    activityIndicator?.center = CGPoint(
      x: bounds.width - padding - (activityIndicator?.bounds.midX ?? 0.0), y: midY)

    // Title label
    var labelFrame = bounds
    // not every icon is `iconWidth` wide, but give them all the same amount of space:
    labelFrame.origin.x = padding + iconWidth + padding
    labelFrame.size.width = (activityIndicator?.frame.minX ?? 0.0) - padding - labelFrame.origin.x
    titleLabel?.frame = labelFrame
  }

  func primaryColorForPaymentOption(withSelected selected: Bool, enabled: Bool) -> UIColor {
    if selected {
      return theme.accentColor
    } else {
      return
        (enabled
        ? theme.primaryForegroundColor : theme.primaryForegroundColor.withAlphaComponent(0.6))
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
