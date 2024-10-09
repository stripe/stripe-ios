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

        static let presentationIsModal = "PresentationIsModal"
        static let disableEmbedInNavbar = "DisableEmbedInNavbar"
        static let embedInTabbar = "EmbedInTabbar"

        // MARK: Onboarding
        static let onboardingTermsOfServiceURL = "OnboardingTermsOfServiceURL"
        static let onboardingrecipientTermsOfServiceString = "OnboardingrecipientTermsOfServiceString"
        static let onboardingPrivacyPolicyString = "OnboardingPrivacyPolicyString"

        static let onboardingSkipTermsOfService = "OnboardingSkipTermsOfService"
        static let onboardingFieldOption = "OnboardingFieldOption"
        static let onboardingFutureRequirements = "OnboardingFutureRequirements"

    }

    static let shared = AppSettings()

    let defaults = UserDefaults.standard

    var selectedServerBaseURL: String {
        get {
            defaults.string(forKey: Constants.serverBaseURLKey) ??
            Constants.defaultServerBaseURL
        }
        set {
            defaults.setValue(newValue, forKey: Constants.serverBaseURLKey)
        }
    }

    var appearanceId: String? {
        get {
            defaults.string(forKey: Constants.appearanceIdKey)
        }
        set {
            defaults.setValue(newValue, forKey: Constants.appearanceIdKey)
        }
    }

    var onboardingSettings: OnboardingSettings {
        get {
            let settings = OnboardingSettings(
                fullTermsOfServiceString: defaults.string(forKey: Constants.onboardingTermsOfServiceURL),
                recipientTermsOfServiceString: defaults.string(forKey: Constants.onboardingrecipientTermsOfServiceString),
                privacyPolicyString: defaults.string(forKey: Constants.onboardingPrivacyPolicyString),
                skipTermsOfService: .init(rawValue: defaults.string(forKey: Constants.onboardingSkipTermsOfService)) ?? .default,
                fieldOption: .init(rawValue: defaults.string(forKey: Constants.onboardingFieldOption)) ?? .default,
                futureRequirement: .init(rawValue: defaults.string(forKey: Constants.onboardingFutureRequirements)) ?? .default
            )
            return settings
        }
        set {
            defaults.setValue(newValue.fullTermsOfServiceString, forKey: Constants.onboardingTermsOfServiceURL)
            defaults.setValue(newValue.recipientTermsOfServiceString, forKey: Constants.onboardingrecipientTermsOfServiceString)
            defaults.setValue(newValue.privacyPolicyString, forKey: Constants.onboardingPrivacyPolicyString)

            defaults.setValue(newValue.skipTermsOfService.rawValue, forKey: Constants.onboardingSkipTermsOfService)
            defaults.setValue(newValue.fieldOption.rawValue, forKey: Constants.onboardingFieldOption)
            defaults.setValue(newValue.futureRequirement.rawValue, forKey: Constants.onboardingFutureRequirements)
            defaults.synchronize()
        }
    }

    var presentationSettings: PresentationSettings {
        get {
            .init(
                presentationStyleIsPush: !defaults.bool(forKey: Constants.presentationIsModal),
                embedInTabBar: defaults.bool(forKey: Constants.embedInTabbar),
                embedInNavBar: !defaults.bool(forKey: Constants.disableEmbedInNavbar)
            )
        }
        set {
            defaults.set(!newValue.presentationStyleIsPush, forKey: Constants.presentationIsModal)
            defaults.set(newValue.embedInTabBar, forKey: Constants.embedInTabbar)
            defaults.set(!newValue.embedInNavBar, forKey: Constants.disableEmbedInNavbar)
        }
    }

    func selectedMerchant(appInfo: AppInfo?) -> MerchantInfo? {
        // Default to the first available merchant if this is the first time opening the app
        guard let merchantId = defaults.string(forKey: Constants.selectedMerchantKey) else {
            return appInfo?.availableMerchants.first
        }

        // If the merchant is in the list of available merchants, then use its display name
        let displayName = appInfo?.availableMerchants.first(where: {
            $0.merchantId == merchantId
        })?.displayName

        return .init(displayName: displayName, merchantId: merchantId)
    }

    func setSelectedMerchant(merchant: MerchantInfo?) {
        defaults.setValue(merchant?.id, forKey: Constants.selectedMerchantKey)
    }
}

private extension UserDefaults {
    func string(forKey defaultName: String, defaultValue: String = "") -> String {
        self.string(forKey: defaultName) ?? defaultValue
    }
}
