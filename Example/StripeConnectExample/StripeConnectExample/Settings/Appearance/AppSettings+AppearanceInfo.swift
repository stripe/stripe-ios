//
//  AppSettings+AppearanceInfo.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/5/24.
//

import Foundation
@_spi(PrivateBetaConnect) import StripeConnect
import UIKit

extension AppSettings {
    var appearanceOptions: [AppearanceInfo] {
        [
            .default,
            .customFont,
            .dynamicColors,
            .hotDog,
            .link,
            .oceanBreeze,
            .ogre,
        ]
    }

    var appearanceInfo: AppearanceInfo {
        get {
            appearanceOptions.first(where: {
                $0.id == AppSettings.shared.appearanceId
            }) ?? .default
        }
        set {
            appearanceId = newValue.id
        }
    }
}

extension AppearanceInfo {
    static var `default`: AppearanceInfo {
        .init(displayName: "Default", appearance: .default)
    }

    static var ogre: AppearanceInfo {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.colors.primary = UIColor(red: 90/255, green: 233/255, blue: 43/255, alpha: 1)
        appearance.colors.background = UIColor(red: 131/255, green: 116/255, blue: 17/255, alpha: 1)
        appearance.buttonPrimary.colorBackground = UIColor(red: 218/255, green: 185/255, blue: 185/255, alpha: 1)
        appearance.buttonPrimary.colorBorder = UIColor(red: 240/255, green: 0/255, blue: 0/255, alpha: 1)
        appearance.buttonPrimary.colorText = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        appearance.buttonSecondary.colorBackground = UIColor(red: 2/255, green: 95/255, blue: 8/255, alpha: 1)
        appearance.colors.text = UIColor(red: 85/255, green: 65/255, blue: 37/255, alpha: 1)
        appearance.badgeNeutral.colorText = UIColor(red: 40/255, green: 215/255, blue: 42/255, alpha: 1)
        appearance.badgeNeutral.colorBackground = UIColor(red: 99/255, green: 136/255, blue: 99/255, alpha: 1)
        appearance.buttonSecondary.colorText = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        return .init(displayName: "Ogre", appearance: appearance)
    }

    static var hotDog: AppearanceInfo {
        var appearance = EmbeddedComponentManager.Appearance()

        appearance.colors.primary = UIColor(red: 255/255, green: 34/255, blue: 0/255, alpha: 1)
        appearance.colors.background = UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 1)
        appearance.buttonSecondary.colorBackground = UIColor(red: 198/255, green: 198/255, blue: 198/255, alpha: 1)
        appearance.buttonSecondary.colorBorder = UIColor(red: 31/255, green: 31/255, blue: 31/255, alpha: 1)
        appearance.buttonPrimary.colorBorder = UIColor(red: 31/255, green: 31/255, blue: 31/255, alpha: 1)
        appearance.buttonPrimary.colorText = UIColor(red: 31/255, green: 31/255, blue: 31/255, alpha: 1)
        appearance.buttonPrimary.colorBackground = UIColor(red: 198/255, green: 198/255, blue: 198/255, alpha: 1)
        appearance.colors.offsetBackground = UIColor(red: 255/255, green: 34/255, blue: 0/255, alpha: 1)
        appearance.colors.text = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        appearance.colors.secondaryText = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
        appearance.badgeDanger.colorText = UIColor(red: 153/255, green: 20/255, blue: 0/255, alpha: 1)
        appearance.badgeWarning.colorBackground = UIColor(red: 249/255, green: 164/255, blue: 67/255, alpha: 1)

        appearance.cornerRadius.base = 0

        return .init(displayName: "Hot Dog Stand", appearance: appearance)
    }

    static var oceanBreeze: AppearanceInfo {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.colors.background = UIColor(red: 234/255, green: 246/255, blue: 251/255, alpha: 1)  // #EAF6FB
        appearance.colors.primary = UIColor(red: 21/255, green: 96/255, blue: 158/255, alpha: 1)  // #15609E
        appearance.badgeSuccess.colorText = UIColor(red: 42/255, green: 96/255, blue: 147/255, alpha: 1)  // #2A6093
        appearance.badgeNeutral.colorText = UIColor(red: 90/255, green: 98/255, blue: 29/255, alpha: 1)  // #5A621D
        appearance.buttonSecondary.colorText = UIColor(red: 44/255, green: 147/255, blue: 232/255, alpha: 1)  // #2C93E8
        appearance.buttonSecondary.colorBorder = UIColor(red: 44/255, green: 147/255, blue: 232/255, alpha: 1)  // #2C93E8
        appearance.cornerRadius.base = 23

        return .init(displayName: "Ocean Breeze", appearance: appearance)
    }

    static var link: AppearanceInfo {
        var appearance = EmbeddedComponentManager.Appearance()

        appearance.colors.primary = UIColor(red: 28/255, green: 57/255, blue: 68/255, alpha: 1)
        appearance.buttonPrimary.colorBackground = UIColor(red: 51/255, green: 220/255, blue: 179/255, alpha: 1)
        appearance.buttonPrimary.colorBorder = UIColor(red: 51/255, green: 220/255, blue: 179/255, alpha: 1)
        appearance.buttonPrimary.colorText = UIColor(red: 28/255, green: 57/255, blue: 68/255, alpha: 1)
        appearance.colors.secondaryText = UIColor(red: 72/255, green: 91/255, blue: 97/255, alpha: 1)
        appearance.colors.text = UIColor(red: 28/255, green: 57/255, blue: 68/255, alpha: 1)
        appearance.colors.actionPrimaryText = UIColor(red: 51/255, green: 220/255, blue: 179/255, alpha: 1)
        appearance.badgeSuccess.colorBackground = UIColor(red: 180/255, green: 254/255, blue: 225/255, alpha: 1)
        appearance.badgeSuccess.colorBorder = UIColor(red: 192/255, green: 215/255, blue: 205/255, alpha: 1)
        appearance.badgeSuccess.colorText = UIColor(red: 28/255, green: 57/255, blue: 68/255, alpha: 1)
        appearance.badgeNeutral.colorBackground = UIColor(red: 222/255, green: 254/255, blue: 204/255, alpha: 1)
        appearance.badgeNeutral.colorText = UIColor(red: 28/255, green: 57/255, blue: 68/255, alpha: 1)

        appearance.cornerRadius.base = 5

        appearance.spacingUnit = 9

        return .init(displayName: "Link", appearance: appearance)
    }

    static var dynamicColors: AppearanceInfo {
        var appearance = EmbeddedComponentManager.Appearance()

        appearance.colors.primary = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xEBF0F4)
            : .init(hex: 0x0969DA)
        }
        appearance.colors.text = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xffffff)
            : .init(hex: 0x24292f)
        }
        appearance.colors.background = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x272626)
            : .init(hex: 0xffffff)
        }
        appearance.buttonPrimary.colorBackground = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x077EDF)
            : .init(hex: 0x0969da)
        }
        appearance.buttonPrimary.colorBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x077EDF)
            : .init(red: 27 / 255, green: 31 / 255, blue: 36 / 255, alpha: 0.15)
        }
        appearance.buttonPrimary.colorText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xffffff)
            : .init(hex: 0xffffff)
        }
        appearance.buttonSecondary.colorBackground = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x3D4042)
            : .init(hex: 0xf6f8fa)
        }
        appearance.buttonSecondary.colorBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x89969F)
            : .init(red: 27 / 255, green: 31 / 255, blue: 36 / 255, alpha: 0.15)
        }
        appearance.buttonSecondary.colorText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xffffff)
            : .init(hex: 0x24292f)
        }
        appearance.colors.border = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x3D3D3D)
            : .init(hex: 0xD7D7D7)
        }
        appearance.colors.secondaryText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xF4F3F3)
            : .init(hex: 0x57606a)
        }
        appearance.colors.actionPrimaryText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xEBF0F4)
            : .init(hex: 0x0969da)
        }
        appearance.colors.actionSecondaryText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xF7F7F7)
            : .init(hex: 0x6e7781)
        }
        appearance.colors.formAccent = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xEbF0F4)
            : .init(hex: 0x0969DA)
        }
        appearance.colors.formHighlightBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x363636)
            : .init(hex: 0x0969DA)
        }
        appearance.colors.danger = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xDF1B41)
            : .init(hex: 0xb35900)
        }
        appearance.badgeNeutral.colorBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x7D7F87)
            : .init(hex: 0x8c959f)
        }
        appearance.badgeNeutral.colorText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xD1D3DC)
            : .init(hex: 0x6e7781)
        }
        appearance.badgeSuccess.colorBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x7A8C7B)
            : .init(hex: 0x218bff)
        }
        appearance.badgeSuccess.colorText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xCFE3D0)
            : .init(hex: 0x0969DA)
        }
        appearance.badgeWarning.colorBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x794A00)
            : .init(hex: 0xd4a72c)
        }
        appearance.badgeWarning.colorText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xE7A288)
            : .init(hex: 0xbf8700)
        }
        appearance.badgeDanger.colorBorder = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x6F2341)
            : .init(hex: 0xdd7815)
        }
        appearance.badgeDanger.colorText = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0xEC93AF)
            : .init(hex: 0xb35900)
        }
        appearance.colors.offsetBackground = .init {
            $0.userInterfaceStyle == .dark
            ? .init(hex: 0x171717)
            : .init(hex: 0xF8F8F8)
        }

        return .init(displayName: "Dynamic colors", appearance: appearance)
    }

    static var customFont: AppearanceInfo {
        var appearance = EmbeddedComponentManager.Appearance()
        appearance.typography.font = UIFont(name: "Handjet-Regular", size: UIFont.systemFontSize)
        return .init(displayName: "Custom Font", appearance: appearance)
    }
}

extension UIColor {
    convenience init(hex: UInt) {
        let r = hex >> 16 & 0xFF
        let g = hex >> 8 & 0xFF
        let b = hex & 0xFF

        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: 1)
    }
}
