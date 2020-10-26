//
//  STPFormTextFieldContainer.swift
//  Stripe
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// STPFormTextFieldContainer is a protocol that views can conform to to provide customization properties for the field form views that they contain.
@objc public protocol STPFormTextFieldContainer: NSObjectProtocol {
  /// The font used in each child field. Default is `.body`.
  var formFont: UIFont { get set }
  /// The text color to be used when entering valid text. Default is `.label` on iOS 13.0 and later and `.darkText` on earlier versions.
  var formTextColor: UIColor { get set }
  /// The text color to be used when the user has entered invalid information,
  /// such as an invalid card number.
  /// Default is `.red`.
  var formTextErrorColor: UIColor { get set }
  /// The text placeholder color used in each child field.
  /// This will also set the color of the card placeholder icon.
  /// Default is `.placeholderText` on iOS 13.0 and `.lightGray` on earlier versions.
  var formPlaceholderColor: UIColor { get set }
  /// The cursor color for the field.
  /// This is a proxy for the view's tintColor property, exposed for clarity only
  /// (in other words, calling setCursorColor is identical to calling setTintColor).
  var formCursorColor: UIColor { get set }
  /// The keyboard appearance for the field.
  /// Default is `.default`.
  var formKeyboardAppearance: UIKeyboardAppearance { get set }
}
