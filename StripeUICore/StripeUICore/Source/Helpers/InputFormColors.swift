//
//  InputFormColors.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) public enum InputFormColors {

    public static var textColor: UIColor {
        return .label
    }

    public static var disabledTextColor: UIColor {
        return .dynamic(
            light: UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 0.6),
            dark: UIColor(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0, alpha: 0.6)
        )
    }

    public static var errorColor: UIColor {
        return .systemRed
    }

    public static var outlineColor: UIColor {
        return UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.36)
    }

    public static var backgroundColor: UIColor {
        return .dynamic(
            light: .systemBackground,
            dark: UIColor(red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18)
        )
    }

    public static var disabledBackgroundColor: UIColor {
        return .dynamic(
            light: UIColor(red: 248.0 / 255.0, green: 248.0 / 255.0, blue: 248.0 / 255.0, alpha: 1),
            dark: UIColor(red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18)
        )
    }
}
