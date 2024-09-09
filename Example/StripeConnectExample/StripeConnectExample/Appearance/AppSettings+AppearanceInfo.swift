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
            .hotDog,
            .link,
            .oceanBreeze,
            .shrek
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
    
    static var shrek: AppearanceInfo {
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
        return .init(displayName: "Shrek", appearance: appearance)
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
}
