//
//  UIView+Helpers.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

protocol SafeAreaLayoutGuide {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

extension UIView: SafeAreaLayoutGuide {}
extension UILayoutGuide: SafeAreaLayoutGuide {}

extension UIView {
    var _safeAreaLayoutGuide: SafeAreaLayoutGuide {
        if #available(iOSApplicationExtension 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return self
        }
    }
}
