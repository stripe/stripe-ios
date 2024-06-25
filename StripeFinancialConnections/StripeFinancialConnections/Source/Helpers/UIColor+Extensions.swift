//
//  Extensions.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/26/21.
//

import UIKit

extension UIColor {

    // The background color we use across across many screens.
    // Added for future support around dark mode.
    static var customBackgroundColor: UIColor {
        return .white
    }

    static var textDefault: UIColor {
        return neutral800
    }

    static var textSubdued: UIColor {
        return neutral600
    }

    static var textActionPrimary: UIColor {
        return brand600
    }

    static var textActionPrimaryFocused: UIColor {
        return brand600
    }

    static var textBrand: UIColor {
        return brand500
    }

    static var textDisabled: UIColor {
        return neutral300
    }

    static var textCritical: UIColor {
        return critical500
    }

    static var textFeedbackCritical: UIColor {
        return feedbackCritical600
    }

    static var textSuccess: UIColor {
        return success500
    }

    static var iconDefault: UIColor {
        return neutral700
    }

    static var iconActionPrimary: UIColor {
        return brand500
    }

    static var borderNeutral: UIColor {
        return neutral150
    }

    static var borderDefault: UIColor {
        return neutral100
    }

    static var borderCritical: UIColor {
        return critical500
    }

    static var backgroundContainer: UIColor {
        return neutral50
    }

    static var backgroundOffset: UIColor {
        return neutral25
    }

    static var attention50: UIColor {
        return UIColor(red: 254 / 255.0, green: 249 / 255.0, blue: 218 / 255.0, alpha: 1)  // #fef9da
    }

    static var attention300: UIColor {
        return UIColor(red: 247 / 255.0, green: 135 / 255.0, blue: 15 / 255.0, alpha: 1)  // #f7870f
    }

    static var neutral0: UIColor {
        return .white
    }

    static var neutral25: UIColor {
        return UIColor(red: 245 / 255.0, green: 246 / 255.0, blue: 248 / 255.0, alpha: 1)  // #f5f6f8
    }

    private static var neutral50: UIColor {
        return UIColor(red: 246 / 255.0, green: 248 / 255.0, blue: 250 / 255.0, alpha: 1)  // #f6f8fa
    }

    private static var neutral100: UIColor {
        return UIColor(red: 216 / 255.0, green: 222 / 255.0, blue: 228 / 255.0, alpha: 1)  // #d8dee4
    }

    private static var neutral150: UIColor {
        return UIColor(red: 224 / 255.0, green: 230 / 255.0, blue: 235 / 255.0, alpha: 1)  // #e0e6eb
    }

    static var neutral200: UIColor {
        return UIColor(red: 192 / 255.0, green: 200 / 255.0, blue: 210 / 255.0, alpha: 1)  // #c0c8d2
    }

    private static var neutral300: UIColor {
        return UIColor(red: 163 / 255.0, green: 172 / 255.0, blue: 186 / 255.0, alpha: 1)  // #a3acba
    }

    private static var neutral500: UIColor {
        return UIColor(red: 106 / 255.0, green: 115 / 255.0, blue: 131 / 255.0, alpha: 1)  // #6a7383
    }

    private static var neutral600: UIColor {
        return UIColor(red: 89 / 255.0, green: 97 / 255.0, blue: 113 / 255.0, alpha: 1)  // #596171
    }

    private static var neutral700: UIColor {
        return UIColor(red: 71 / 255.0, green: 78 / 255.0, blue: 90 / 255.0, alpha: 1)  // #474e5a
    }

    private static var neutral800: UIColor {
        return UIColor(red: 53 / 255.0, green: 58 / 255.0, blue: 68 / 255.0, alpha: 1)  // #353a44
    }

    static var brand25: UIColor {
        return UIColor(red: 247 / 255.0, green: 245 / 255.0, blue: 253 / 255.0, alpha: 1)  // #f7f5fd
    }

    static var brand100: UIColor {
        return UIColor(red: 242 / 255.0, green: 235 / 255.0, blue: 255 / 255.0, alpha: 1)  // #f2ebff
    }

    static var brand500: UIColor {
        return UIColor(red: 103 / 255.0, green: 93 / 255.0, blue: 255 / 255.0, alpha: 1)  // #675dff
    }

    private static var brand600: UIColor {
        return UIColor(red: 83 / 255.0, green: 58 / 255.0, blue: 253 / 255.0, alpha: 1)  // #533afd
    }

    private static var critical500: UIColor {
        return UIColor(red: 223 / 255.0, green: 27 / 255.0, blue: 65 / 255.0, alpha: 1)  // #df1b41
    }

    private static var feedbackCritical600: UIColor {
        return UIColor(red: 192 / 255.0, green: 18 / 255.0, blue: 60 / 255.0, alpha: 1)  // #c0123c
    }

    static var success100: UIColor {
        return UIColor(red: 215 / 255.0, green: 247 / 255.0, blue: 194 / 255.0, alpha: 1)  // #d7f7c2
    }

    private static var success500: UIColor {
        return UIColor(red: 34 / 255.0, green: 132 / 255.0, blue: 3 / 255.0, alpha: 1)  // #228403
    }

    static var linkBrand200: UIColor {
        return UIColor(red: 166 / 255.0, green: 251 / 255.0, blue: 221 / 255.0, alpha: 1)  // #a6fbdd
    }

    static var linkBrand600: UIColor {
        return UIColor(red: 26 / 255.0, green: 197 / 255.0, blue: 155 / 255.0, alpha: 1)  // #1ac59b
    }

    static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
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
}
