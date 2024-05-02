//
//  ExampleAppearanceOptions.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/1/24.
//

import StripeConnect
import UIKit

/// A collection of example appearance options
enum ExampleAppearanceOptions: String, CaseIterable {
    case `default` = "Default"
    case purpleHaze = "Purple haze"
//    case ogre = "Ogre"
//    case darkMode = "Dark mode"
//    case protanopia = "Protanopia"
//    case ninetyFive = "'95"
//    case oceanBreeze = "Ocean breeze"
//    case yeOldeTimes = "Ye olde times"
//    case matrix = "Matrix"
//    case cloud = "Cloud"
//    case hotDog = "Hot dog"
//    case thisIsFine = "This is fine"
//    case bubbleGum = "Bubblegum"
//    case jazzCup = "Jazz cup"

    var label: String { rawValue }
}

extension StripeConnectInstance.Appearance {
    init(_ selection: ExampleAppearanceOptions) {
        self = .default

        switch selection {
        case .default:
            break

        case .purpleHaze:
            // TODO: These text colors are causing a failure with the contrast checker
            colorPrimary = .init(hex: 0x414AC3)
            colorBackground = .init(hex: 0xE0C3FC)
            badgeNeutralColorBackground = .init(hex: 0xF2E8F8)
//            badgeNeutralColorText = .white
//            badgeSuccessColorText = .white
            badgeSuccessColorBackground = .init(hex: 0x8E94F2)
            badgeSuccessColorBorder = .white
//            badgeWarningColorText = .init(hex: 0x3B3B3B)
            badgeWarningColorBackground = .init(hex: 0xFFC2E2)
            badgeWarningColorBorder = .white
//            badgeDangerColorText = .white
            badgeDangerColorBackground = .init(hex: 0xEF7A85)
            badgeDangerColorBorder = .white
            badgeBorderRadius = 24
            spacingUnit = 9
            labelMdTextTransform = .uppercase
            labelSmTextTransform = .uppercase
            headingLgTextTransform = .uppercase
            headingMdTextTransform = .uppercase
            headingSmTextTransform = .uppercase
            headingXlTextTransform = .uppercase
            headingXsTextTransform = .uppercase
//            fontFamily = "Brush Script MT"
            fontFamily = "Snell Roundhand"
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
