//
//  STPLabeledFormTextFieldView.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

let kLabeledFormFieldHeight: CGFloat = 44.0
let kLabeledFormVeriticalMargin: CGFloat = 4.0
let kLabeledFormHorizontalMargin: CGFloat = 12.0

class STPLabeledFormTextFieldView: STPViewWithSeparator {
  private var formLabel: UILabel?

  @objc init(formLabel formLabelText: String, textField: STPFormTextField) {
    super.init(frame: CGRect.zero)
    let formLabel = UILabel()
    formLabel.text = formLabelText
    formLabel.font = textField.font
    formLabel.textColor = textField.defaultColor
    // We want the textField to fill additional space so set the label's contentHuggingPriority to high
    formLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    formLabel.translatesAutoresizingMaskIntoConstraints = false
    textField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(formLabel)
    addSubview(textField)

    var constraints = [
      formLabel.widthAnchor.constraint(
        lessThanOrEqualTo: layoutMarginsGuide.widthAnchor, multiplier: 0.5),
      heightAnchor.constraint(greaterThanOrEqualToConstant: kLabeledFormFieldHeight),
      textField.centerYAnchor.constraint(equalTo: centerYAnchor),
      formLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
      topAnchor.anchorWithOffset(to: textField.topAnchor).constraint(
        greaterThanOrEqualToConstant: kLabeledFormVeriticalMargin),
      topAnchor.anchorWithOffset(to: formLabel.topAnchor).constraint(
        greaterThanOrEqualToConstant: kLabeledFormVeriticalMargin),
      // constraining the height here works around an issue where UITextFields without a border style
      // change height slightly when they become or resign first responder
      textField.heightAnchor.constraint(
        equalToConstant: textField.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height),
    ]

    constraints.append(
      contentsOf: [
        formLabel.leadingAnchor.constraint(
          equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.0),
        textField.leadingAnchor.constraint(
          equalToSystemSpacingAfter: formLabel.trailingAnchor, multiplier: 2.0),
        layoutMarginsGuide.trailingAnchor.constraint(
          equalToSystemSpacingAfter: textField.trailingAnchor, multiplier: 1.0),
      ])

    labelWidthDimension = formLabel.widthAnchor
    self.formLabel = formLabel

    NSLayoutConstraint.activate(constraints)
  }

  @objc var formBackgroundColor: UIColor? {
    get {
      return backgroundColor ?? UIColor.clear
    }
    set(formBackgroundColor) {
      backgroundColor = formBackgroundColor
    }
  }
  // Initializes to textField.defaultColor

  var formLabelTextColor: UIColor? {
    get {
      return formLabel?.textColor ?? UIColor.clear
    }
    set(formLabelTextColor) {
      formLabel?.textColor = formLabelTextColor
    }
  }
  // Initializes to textField.font

  var formLabelFont: UIFont? {
    get {
      return (formLabel?.font)!
    }
    set(formLabelFont) {
      formLabel?.font = formLabelFont
    }
  }
  private(set) var labelWidthDimension = NSLayoutDimension()

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
