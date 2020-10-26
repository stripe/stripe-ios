//
//  STPPaymentCardTextFieldCell.swift
//  Stripe
//
//  Created by Jack Flintermann on 6/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

class STPPaymentCardTextFieldCell: UITableViewCell {
  private(set) weak var paymentField: STPPaymentCardTextField?

  var theme: STPTheme = STPTheme.defaultTheme {
    didSet {
      updateAppearance()
    }
  }

  private var _inputAccessoryView: UIView?
  override var inputAccessoryView: UIView? {
    get {
      _inputAccessoryView
    }
    set(inputAccessoryView) {
      _inputAccessoryView = inputAccessoryView
      paymentField?.inputAccessoryView = inputAccessoryView
    }
  }

  func isEmpty() -> Bool {
    return (paymentField?.cardNumber?.count ?? 0) == 0
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    let paymentField = STPPaymentCardTextField(frame: bounds)
    paymentField.postalCodeEntryEnabled = false
    contentView.addSubview(paymentField)
    self.paymentField = paymentField
    theme = STPTheme.defaultTheme
    updateAppearance()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    paymentField?.frame = contentView.bounds
  }

  @objc func updateAppearance() {
    paymentField?.backgroundColor = UIColor.clear
    paymentField?.placeholderColor = theme.tertiaryForegroundColor
    paymentField?.borderColor = UIColor.clear
    paymentField?.textColor = theme.primaryForegroundColor
    paymentField?.textErrorColor = theme.errorColor
    paymentField?.font = theme.font
    backgroundColor = theme.secondaryBackgroundColor
  }

  @objc override func becomeFirstResponder() -> Bool {
    return paymentField?.becomeFirstResponder() ?? false
  }

  override func accessibilityElementCount() -> Int {
    return paymentField?.allFields.count ?? 0
  }

  override func accessibilityElement(at index: Int) -> Any? {
    return paymentField?.allFields[index]
  }

  override func index(ofAccessibilityElement element: Any) -> Int {
    let fields = paymentField?.allFields
    for i in 0..<(fields?.count ?? 0) {
      if (element as? AnyHashable) == fields?[i] {
        return i
      }
    }
    return 0
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}
