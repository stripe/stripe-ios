//
//  STPSectionHeaderView.swift
//  Stripe
//
//  Created by Ben Guo on 1/3/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

class STPSectionHeaderView: UIView {
  private var _theme: STPTheme = STPTheme.defaultTheme
  var theme: STPTheme {
    get {
      _theme
    }
    set(theme) {
      _theme = theme
      updateAppearance()
    }
  }

  private var _title: String?
  var title: String? {
    get {
      _title
    }
    set(title) {
      _title = title
      if let title = title {
        let style = NSMutableParagraphStyle()
        style.firstLineHeadIndent = 15
        style.headIndent = style.firstLineHeadIndent
        let attributes = [
          NSAttributedString.Key.paragraphStyle: style
        ]
        label?.attributedText = NSAttributedString(
          string: title,
          attributes: attributes)
      } else {
        label?.attributedText = nil
      }
      setNeedsLayout()
    }
  }
  weak var button: UIButton?

  private var _buttonHidden = false
  var buttonHidden: Bool {
    get {
      _buttonHidden
    }
    set(buttonHidden) {
      _buttonHidden = buttonHidden
      button?.alpha = buttonHidden ? 0 : 1
    }
  }
  private weak var label: UILabel?
  private var buttonInsets: UIEdgeInsets!

  override init(frame: CGRect) {
    super.init(frame: frame)
    let label = UILabel()
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.accessibilityTraits.insert(.header)
    addSubview(label)
    self.label = label
    let button = UIButton(type: .system)
    button.contentHorizontalAlignment = .right
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.lineBreakMode = .byWordWrapping
    button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
    button.contentEdgeInsets = .zero
    addSubview(button)
    self.button = button
    buttonInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 15)
    backgroundColor = UIColor.clear
    updateAppearance()
  }

  @objc func updateAppearance() {
    label?.font = theme.smallFont
    label?.textColor = theme.secondaryForegroundColor
    button?.titleLabel?.font = theme.smallFont
    button?.tintColor = theme.accentColor
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let bounds = stp_boundsWithHorizontalSafeAreaInsets()
    if buttonHidden {
      label?.frame = bounds
    } else {
      let halfWidth = bounds.size.width / 2
      let heightThatFits = self.heightThatFits(bounds.size)
      label?.frame = CGRect(
        x: bounds.origin.x,
        y: bounds.origin.y,
        width: halfWidth,
        height: heightThatFits)
      button?.frame = CGRect(
        x: bounds.origin.x + halfWidth,
        y: bounds.origin.y,
        width: halfWidth,
        height: heightThatFits)
    }
  }

  func heightThatFits(_ size: CGSize) -> CGFloat {
    let labelPadding: CGFloat = 16
    if buttonHidden {
      let labelHeight = label?.sizeThatFits(size).height ?? 0.0
      return labelHeight + labelPadding
    } else {
      let halfSize = CGSize(width: size.width / 2, height: size.height)
      let labelHeight = (label?.sizeThatFits(halfSize).height ?? 0.0) + labelPadding
      let buttonHeight = height(forButtonText: button?.titleLabel?.text, width: halfSize.width)
      return CGFloat(max(buttonHeight, labelHeight))
    }
  }

  func height(forButtonText text: String?, width: CGFloat) -> CGFloat {
    let insets = buttonInsets
    let textSize = CGSize(
      width: width - (insets?.left ?? 0.0) - (insets?.right ?? 0.0),
      height: CGFloat.greatestFiniteMagnitude)
    var attributes: [NSAttributedString.Key: Any]?
    if let font1 = button?.titleLabel?.font {
      attributes = [
        NSAttributedString.Key.font: font1
      ]
    }
    let buttonSize = text?.boundingRect(
      with: textSize,
      options: .usesLineFragmentOrigin,
      attributes: attributes,
      context: nil
    ).size
    return (buttonSize?.height ?? 0.0) + (insets?.top ?? 0.0) + (insets?.bottom ?? 0.0)
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    return CGSize(width: size.width, height: heightThatFits(size))
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
