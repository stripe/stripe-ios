//
//  AppSettings.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/25/24.
//

import Foundation

class AppSettings {
    enum  Constants {
        static let defaultServerBaseURL = "https://stripe-connect-mobile-example-v1.glitch.me/"
        static let serverBaseURLKey = "ServerBaseURL"
        static let appearanceIdKey = "AppearanceId"

        static let selectedMerchantKey = "SelectedMerchant"
    }
    
    static let shared = AppSettings()
    
    var selectedServerBaseURL: String {
        get {
            UserDefaults.standard.string(forKey: Constants.serverBaseURLKey) ??
            Constants.defaultServerBaseURL
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.serverBaseURLKey)
        }
    }
    
    var appearanceId: String? {
        get {
            UserDefaults.standard.string(forKey: Constants.appearanceIdKey) ??
            nil
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: Constants.appearanceIdKey)
        }
    }
    
    func selectedMerchant(appInfo: AppInfo?) -> MerchantInfo? {
        let merchantId = UserDefaults.standard.string(forKey: Constants.selectedMerchantKey)
        return appInfo?.availableMerchants.first(where: {
            $0.merchantId == merchantId
        }) ?? appInfo?.availableMerchants.first
    }
    
    func setSelectedMerchant(merchant: MerchantInfo?) {
        UserDefaults.standard.setValue(merchant?.id, forKey: Constants.selectedMerchantKey)
    }
}
