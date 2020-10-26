//
//  STPValidatedTextField.swift
//  StripeiOS
//
//  Created by Daniel Jackson on 12/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import UIKit

/// A UITextField that changes the text color, based on the validity of
/// its contents.
/// This does *not* (currently?) have any logic or hooks for determining whether
/// the contents are valid, that must be done by something else.
class STPValidatedTextField: UITextField {
  /// color to use for `text` when `validText` is YES

  private var _defaultColor: UIColor?
  var defaultColor: UIColor? {
    get {
      _defaultColor
    }
    set(defaultColor) {
      _defaultColor = defaultColor
      updateColor()
    }
  }
  /// color to use for `text` when `validText` is NO

  private var _errorColor: UIColor?
  var errorColor: UIColor? {
    get {
      _errorColor
    }
    set(errorColor) {
      _errorColor = errorColor
      updateColor()
    }
  }
  /// color to use for `placeholderText`, displayed when `text` is empty

  private var _placeholderColor: UIColor?
  @objc var placeholderColor: UIColor? {
    get {
      _placeholderColor
    }
    set(placeholderColor) {
      _placeholderColor = placeholderColor
      self._updateAttributedPlaceholder()
    }
  }
  /// flag to indicate whether the contents are valid or not.

  private var _validText = false
  @objc var validText: Bool {
    get {
      _validText
    }
    set(validText) {
      _validText = validText
      updateColor()
    }
  }

  func _updateAttributedPlaceholder() {
    let nonNilPlaceholder = placeholder ?? ""
    let attributedPlaceholder = NSAttributedString(
      string: nonNilPlaceholder,
      attributes: placeholderTextAttributes() as? [NSAttributedString.Key: Any])
    self.attributedPlaceholder = attributedPlaceholder
  }
  // MARK: - Property Overrides

  // MARK: - UITextField overrides
  /// :nodoc:
  @objc public override var placeholder: String? {
    get {
      return super.placeholder
    }
    set(placeholder) {
      super.placeholder = placeholder
      self._updateAttributedPlaceholder()
    }
  }

  // MARK: - Private Methods
  func updateColor() {
    textColor = validText ? defaultColor : errorColor
  }

  func placeholderTextAttributes() -> [AnyHashable: Any]? {
    var defaultAttributes = defaultTextAttributes
    if let placeholderColor = placeholderColor {
      defaultAttributes[NSAttributedString.Key.foregroundColor] = placeholderColor
    }
    return defaultAttributes
  }
}
