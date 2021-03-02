//
//  STPInputFormColors.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/23/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPInputFormColors: NSObject {

    static var textColor: UIColor {
        return CompatibleColor.label
    }

    static var disabledTextColor: UIColor {
        return UIColor.dynamic(
            light: UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 0.6),
            dark: UIColor(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0, alpha: 0.6)
        )
    }

    static var errorColor: UIColor {
        return .systemRed
    }

    static var outlineColor: UIColor {
        return UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.36)
    }

    static var backgroundColor: UIColor {
        return UIColor.dynamic(
            light: CompatibleColor.systemBackground,
            dark: UIColor(
                red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18))
    }

    static var disabledBackgroundColor: UIColor {
        return UIColor.dynamic(
            light: UIColor(red: 248.0 / 255.0, green: 248.0 / 255.0, blue: 248.0 / 255.0, alpha: 1),
            dark: UIColor(
                red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18))
    }

}
