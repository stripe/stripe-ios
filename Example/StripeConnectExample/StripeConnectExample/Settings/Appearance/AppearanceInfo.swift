//
//  AppearanceInfo.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/5/24.
//

import Foundation
@_spi(PrivateBetaConnect) import StripeConnect

struct AppearanceInfo: Identifiable {
    var id: String {
        return displayName
    }
    let displayName: String
    var appearance: EmbeddedComponentManager.Appearance
}
