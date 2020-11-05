//
//  STPLabeledMultiFormTextFieldView.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPLabeledMultiFormTextFieldView: UIView {
  private var fieldContainer: STPViewWithSeparator?

  init(
    formLabel formLabelText: String,
    firstTextField textField1: STPFormTextField,
    secondTextField textField2: STPFormTextField
  ) {
    super.init(frame: CGRect.zero)
    let formLabel = UILabel()
    formLabel.text = formLabelText
    formLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
    if #available(iOS 13.0, *) {
      formLabel.textColor = UIColor.secondaryLabel
    } else {
      // Fallback on earlier versions
      formLabel.textColor = UIColor.darkGray
    }
    formLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(formLabel)

    let fieldContainer = STPViewWithSeparator()
    if #available(iOS 13.0, *) {
      fieldContainer.backgroundColor = UIColor.systemBackground
    } else {
      // Fallback on earlier versions
      fieldContainer.backgroundColor = UIColor.white
    }

    textField1.translatesAutoresizingMaskIntoConstraints = false
    textField2.translatesAutoresizingMaskIntoConstraints = false
    fieldContainer.addSubview(textField1)
    fieldContainer.addSubview(textField2)

    fieldContainer.translatesAutoresizingMaskIntoConstraints = false
    addSubview(fieldContainer)

    var constraints = [
      formLabel.topAnchor.constraint(equalTo: topAnchor, constant: kLabeledFormVeriticalMargin),
      fieldContainer.topAnchor.constraint(
        equalTo: formLabel.bottomAnchor, constant: kLabeledFormVeriticalMargin),
      fieldContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: kLabeledFormFieldHeight),
      bottomAnchor.constraint(equalTo: fieldContainer.bottomAnchor),
      fieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
      fieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
      textField1.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
      textField2.centerYAnchor.constraint(equalTo: fieldContainer.centerYAnchor),
      textField1.trailingAnchor.constraint(
        equalTo: centerXAnchor, constant: -0.5 * kLabeledFormHorizontalMargin),
      textField2.leadingAnchor.constraint(
        equalTo: centerXAnchor, constant: 0.5 * kLabeledFormHorizontalMargin),
      fieldContainer.topAnchor.anchorWithOffset(to: textField1.topAnchor).constraint(
        greaterThanOrEqualToConstant: kLabeledFormVeriticalMargin),
      fieldContainer.topAnchor.anchorWithOffset(to: textField2.topAnchor).constraint(
        greaterThanOrEqualToConstant: kLabeledFormVeriticalMargin),
      // constraining the height here works around an issue where UITextFields without a border style
      // change height slightly when they become or resign first responder
      textField1.heightAnchor.constraint(
        equalToConstant: textField1.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
      ),
      textField2.heightAnchor.constraint(
        equalToConstant: textField2.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
      ),
    ]

    constraints.append(
      contentsOf: [
        formLabel.leadingAnchor.constraint(
          equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.0),
        layoutMarginsGuide.trailingAnchor.constraint(
          greaterThanOrEqualToSystemSpacingAfter: formLabel.trailingAnchor, multiplier: 1.0),
        textField1.leadingAnchor.constraint(
          equalToSystemSpacingAfter: layoutMarginsGuide.leadingAnchor, multiplier: 1.0),
        layoutMarginsGuide.trailingAnchor.constraint(
          equalToSystemSpacingAfter: textField2.trailingAnchor, multiplier: 1.0),
      ])

    NSLayoutConstraint.activate(constraints)

    self.fieldContainer = fieldContainer
  }

  @objc var formBackgroundColor: UIColor? {
    get {
      return fieldContainer?.backgroundColor ?? UIColor.clear
    }
    set(formBackgroundColor) {
      fieldContainer?.backgroundColor = formBackgroundColor
    }
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
