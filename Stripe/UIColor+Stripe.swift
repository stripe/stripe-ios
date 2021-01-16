//
//  UIColor+Stripe.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/16/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(dynamicProvider: {
                switch $0.userInterfaceStyle {
                case .light, .unspecified:
                    return light
                case .dark:
                    return dark
                @unknown default:
                    return light
                }
            })
        }
        return light
    }
}
