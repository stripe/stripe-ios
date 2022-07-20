//
//  Extensions.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/26/21.
//

import UIKit

extension UIColor {
    
    // TODO(kgaidis): the background color we use
    // across many screens. added for future support around dark mode
    static var customBackgroundColor: UIColor {
        return .white
    }
    
    static var textPrimary: UIColor {
        return neutral800
    }
    
    static var textSecondary: UIColor {
        return neutral500
    }
    
    static var textBrand: UIColor {
        return brand500
    }
    
    static var textDisabled: UIColor {
        return neutral300
    }
    
    static var borderNeutral: UIColor {
        return neutral150
    }
    
    static var backgroundContainer: UIColor {
        return neutral50
    }
    
    private static var neutral50: UIColor {
        return UIColor(red: 246 / 255.0, green: 248 / 255.0, blue: 250 / 255.0, alpha: 1) // #f6f8fa
    }
    
    private static var neutral150: UIColor {
        return UIColor(red: 224 / 255.0, green: 230 / 255.0, blue: 235 / 255.0, alpha: 1) // #e0e6eb
    }
    
    private static var neutral300: UIColor {
        return UIColor(red: 163 / 255.0, green: 172 / 255.0, blue: 186 / 255.0, alpha: 1) // #a3acba
    }
    
    private static var neutral500: UIColor {
        return UIColor(red: 106 / 255.0, green: 115 / 255.0, blue: 131 / 255.0, alpha: 1) // #6a7383
    }
    
    private static var neutral800: UIColor {
        return UIColor(red: 48 / 255.0, green: 49 / 255.0, blue: 61 / 255.0, alpha: 1) // #30313d
    }
    
    private static var brand500: UIColor {
        return UIColor(red: 99 / 255.0, green: 91 / 255.0, blue: 255 / 255.0, alpha: 1) // #635bff
    }
    
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
