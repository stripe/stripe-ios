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
    case ogre = "Ogre"
    case protanopia = "Protanopia"
    case oceanBreeze = "🌊 Ocean breeze"
    case hotDog = "🌭 Hot dog"
    case jazzCup = "Jazz cup"

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
            colorPrimary = UIColor(hex: 0x414AC3)
            colorBackground = UIColor(hex: 0xE0C3FC)
            badgeNeutralColorBackground = UIColor(hex: 0xF2E8F8)
//            badgeNeutralColorText = .white
//            badgeSuccessColorText = .white
            badgeSuccessColorBackground = UIColor(hex: 0x8E94F2)
            badgeSuccessColorBorder = .white
//            badgeWarningColorText = UIColor(hex: 0x3B3B3B)
            badgeWarningColorBackground = UIColor(hex: 0xFFC2E2)
            badgeWarningColorBorder = .white
//            badgeDangerColorText = .white
            badgeDangerColorBackground = UIColor(hex: 0xEF7A85)
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

        case .ogre:
            colorPrimary = UIColor(hex: 0x5AE92B)
            colorText = UIColor(hex: 0x554125)
            colorBackground = UIColor(hex: 0x837411)
            buttonPrimaryColorBackground = UIColor(hex: 0xDAB9B9)
            buttonPrimaryColorBorder = UIColor(hex: 0xF00000)
            buttonPrimaryColorText = UIColor(hex: 0x000000)
            buttonSecondaryColorBackground = UIColor(hex: 0x025F08)
            buttonSecondaryColorText = UIColor(hex: 0x000000)
            badgeNeutralColorBackground = UIColor(hex: 0x638863)
            badgeNeutralColorText = UIColor(hex: 0x28D72A)
//            fontFamily = "fantasy"

        case .protanopia:
            colorPrimary = UIColor(hex: 0x0969DA)
            colorText = UIColor(hex: 0x24292f)
            colorBackground = UIColor(hex: 0xffffff)
            buttonPrimaryColorBackground = UIColor(hex: 0x0969da)
            buttonPrimaryColorBorder = UIColor(red: 27.0 / 255, green: 31.0 / 255, blue: 36.0 / 255, alpha: 0.15)
            buttonPrimaryColorText = UIColor(hex: 0xffffff)
            buttonSecondaryColorBackground = UIColor(hex: 0xf6f8fa)
            buttonSecondaryColorBorder = UIColor(red: 27.0 / 255, green: 31.0 / 255, blue: 36.0 / 255, alpha: 0.15)
            buttonSecondaryColorText = UIColor(hex: 0x24292f)
            colorSecondaryText = UIColor(hex: 0x57606a)
            actionPrimaryColorText = UIColor(hex: 0x0969da)
            actionSecondaryColorText = UIColor(hex: 0x6e7781)
            formAccentColor = UIColor(hex: 0x0969DA)
            colorDanger = UIColor(hex: 0xb35900)
            badgeNeutralColorBorder = UIColor(hex: 0x8c959f)
            badgeNeutralColorText = UIColor(hex: 0x6e7781)
            badgeSuccessColorBorder = UIColor(hex: 0x218bff)
            badgeSuccessColorText = UIColor(hex: 0x0969DA)
            badgeWarningColorBorder = UIColor(hex: 0xd4a72c)
            badgeWarningColorText = UIColor(hex: 0xbf8700)
            badgeDangerColorBorder = UIColor(hex: 0xdd7815)
            badgeDangerColorText = UIColor(hex: 0xb35900)
            spacingUnit = 8

        case .oceanBreeze:
            colorPrimary = UIColor(hex: 0x15609E)
            colorBackground = UIColor(hex: 0xEAF6FB)
            buttonSecondaryColorBorder = UIColor(hex: 0x2C93E8)
            buttonSecondaryColorText = UIColor(hex: 0x2C93E8)
            badgeNeutralColorText = UIColor(hex: 0x5A621D)
            badgeSuccessColorText = UIColor(hex: 0x2A6093)
            borderRadius = 23

        case .hotDog:
            colorPrimary = UIColor(hex: 0xFF2200)
            colorText = UIColor(hex: 0x000000)
            colorBackground = UIColor(hex: 0xffff00)
            buttonPrimaryColorBackground = UIColor(hex: 0xc6c6c6)
            buttonPrimaryColorBorder = UIColor(hex: 0x1f1f1f)
            buttonPrimaryColorText = UIColor(hex: 0x1f1f1f)
            buttonSecondaryColorBackground = UIColor(hex: 0xc6c6c6)
            buttonSecondaryColorBorder = UIColor(hex: 0x1f1f1f)
            colorSecondaryText = UIColor(hex: 0x000000)
            badgeWarningColorBackground = UIColor(hex: 0xF9A443)
            badgeDangerColorText = UIColor(hex: 0x991400)
            offsetBackgroundColor = UIColor(hex: 0xFF2200)
            borderRadius = 0
            fontFamily = "Gill Sans"

        case .jazzCup:
            colorPrimary = UIColor(hex: 0x2C1679)
            colorText = UIColor(hex: 0x2C1679)
            buttonSecondaryColorBackground = UIColor(hex: 0x0CCDDB)
            buttonSecondaryColorText = UIColor(hex: 0x2C1679)
            colorSecondaryText = UIColor(hex: 0x871CA1)
            actionPrimaryColorText = UIColor(hex: 0x0CCDDB)
            colorBorder = UIColor(hex: 0x871CA1)
            offsetBackgroundColor = UIColor(hex: 0xFFFFFF)
            fontFamily = "Chalkboard SE"
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
