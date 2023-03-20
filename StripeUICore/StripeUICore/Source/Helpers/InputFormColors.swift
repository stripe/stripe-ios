//
//  InputFormColors.swift
//  StripeUICore
//
//  Created by Cameron Sabol on 9/22/21.
//

import UIKit

@_spi(STP) public enum InputFormColors {

    public static var textColor: UIColor {
        return CompatibleColor.label
    }

    public static var disabledTextColor: UIColor {
        let light = UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 0.6)
        let dark = UIColor(red: 235.0 / 255.0, green: 235.0 / 255.0, blue: 245.0 / 255.0, alpha: 0.6)
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
        } else {
            return light
        }
    }

    public static var errorColor: UIColor {
        return .systemRed
    }

    public static var outlineColor: UIColor {
        return UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.36)
    }

    public static var backgroundColor: UIColor {
        let light = CompatibleColor.systemBackground
        let dark = UIColor(red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18)
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
        } else {
            return light
        }
    }

    public static var disabledBackgroundColor: UIColor {
        let light = UIColor(red: 248.0 / 255.0, green: 248.0 / 255.0, blue: 248.0 / 255.0, alpha: 1)
        let dark = UIColor(red: 116.0 / 255.0, green: 116.0 / 255.0, blue: 128.0 / 255.0, alpha: 0.18)
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
        } else {
            return light
        }
    }
}
