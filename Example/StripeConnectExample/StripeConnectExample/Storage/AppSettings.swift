//
//  AppSettings.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/25/24.
//

import Foundation
@_spi(DashboardOnly) import StripeConnect

class AppSettings {
    enum  Constants {
        // View and fork the backend code here: https://codesandbox.io/p/devbox/dvmfpc
        static let defaultServerBaseURL = "https://stripe-connect-mobile-example-v1.stripedemos.com/"
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
        static let onboardingRequirementsOption = "OnboardingRequirementsOption"
        static let onboardingRequirementsString = "OnboardingRequirementsString"

        // MARK: Payments
        static let paymentsAmountFilterType = "PaymentsAmountFilterType"
        static let paymentsAmountValue = "PaymentsAmountValue"
        static let paymentsAmountLowerBound = "PaymentsAmountLowerBound"
        static let paymentsAmountUpperBound = "PaymentsAmountUpperBound"
        static let paymentsDateFilterType = "PaymentsDateFilterType"
        static let paymentsBeforeDate = "PaymentsBeforeDate"
        static let paymentsAfterDate = "PaymentsAfterDate"
        static let paymentsStartDate = "PaymentsStartDate"
        static let paymentsEndDate = "PaymentsEndDate"
        static let paymentsSelectedStatuses = "PaymentsSelectedStatuses"
        static let paymentsSelectedPaymentMethod = "PaymentsSelectedPaymentMethod"

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
            var settings = OnboardingSettings(
                fullTermsOfServiceString: defaults.string(forKey: Constants.onboardingTermsOfServiceURL),
                recipientTermsOfServiceString: defaults.string(forKey: Constants.onboardingrecipientTermsOfServiceString),
                privacyPolicyString: defaults.string(forKey: Constants.onboardingPrivacyPolicyString),
                skipTermsOfService: .init(rawValue: defaults.string(forKey: Constants.onboardingSkipTermsOfService)) ?? .default,
                fieldOption: .init(rawValue: defaults.string(forKey: Constants.onboardingFieldOption)) ?? .default,
                futureRequirement: .init(rawValue: defaults.string(forKey: Constants.onboardingFutureRequirements)) ?? .default,
                requirementsOption: .init(rawValue: defaults.string(forKey: Constants.onboardingRequirementsOption)) ?? .default,
                requirementsString: defaults.string(forKey: Constants.onboardingRequirementsString)
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

            defaults.setValue(newValue.requirementsOption.rawValue, forKey: Constants.onboardingRequirementsOption)
            defaults.setValue(newValue.requirementsString, forKey: Constants.onboardingRequirementsString)

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

    var paymentsSettings: PaymentsSettings {
        get {
            let amountFilterType = PaymentsSettings.AmountFilterType(rawValue: defaults.string(forKey: Constants.paymentsAmountFilterType)) ?? .none
            let dateFilterType = PaymentsSettings.DateFilterType(rawValue: defaults.string(forKey: Constants.paymentsDateFilterType)) ?? .none

            // Load selected statuses from stored strings
            let statusStrings = defaults.array(forKey: Constants.paymentsSelectedStatuses) as? [String] ?? []
            let selectedStatuses = Set(statusStrings)

            // Load selected payment method
            let selectedPaymentMethod = defaults.string(forKey: Constants.paymentsSelectedPaymentMethod)

            return PaymentsSettings(
                amountFilterType: amountFilterType,
                amountValue: defaults.string(forKey: Constants.paymentsAmountValue, defaultValue: ""),
                amountLowerBound: defaults.string(forKey: Constants.paymentsAmountLowerBound, defaultValue: ""),
                amountUpperBound: defaults.string(forKey: Constants.paymentsAmountUpperBound, defaultValue: ""),
                dateFilterType: dateFilterType,
                beforeDate: defaults.object(forKey: Constants.paymentsBeforeDate) as? Date ?? Date(),
                afterDate: defaults.object(forKey: Constants.paymentsAfterDate) as? Date ?? Date(),
                startDate: defaults.object(forKey: Constants.paymentsStartDate) as? Date ?? Date(),
                endDate: defaults.object(forKey: Constants.paymentsEndDate) as? Date ?? Date(),
                selectedStatuses: selectedStatuses,
                selectedPaymentMethod: selectedPaymentMethod
            )
        }
        set {
            defaults.setValue(newValue.amountFilterType.rawValue, forKey: Constants.paymentsAmountFilterType)
            defaults.setValue(newValue.amountValue, forKey: Constants.paymentsAmountValue)
            defaults.setValue(newValue.amountLowerBound, forKey: Constants.paymentsAmountLowerBound)
            defaults.setValue(newValue.amountUpperBound, forKey: Constants.paymentsAmountUpperBound)
            defaults.setValue(newValue.dateFilterType.rawValue, forKey: Constants.paymentsDateFilterType)
            defaults.setValue(newValue.beforeDate, forKey: Constants.paymentsBeforeDate)
            defaults.setValue(newValue.afterDate, forKey: Constants.paymentsAfterDate)
            defaults.setValue(newValue.startDate, forKey: Constants.paymentsStartDate)
            defaults.setValue(newValue.endDate, forKey: Constants.paymentsEndDate)

            // Save selected statuses as strings
            let statusStrings = Array(newValue.selectedStatuses)
            defaults.setValue(statusStrings, forKey: Constants.paymentsSelectedStatuses)

            // Save selected payment method as string
            if let paymentMethod = newValue.selectedPaymentMethod {
                defaults.setValue(paymentMethod, forKey: Constants.paymentsSelectedPaymentMethod)
            } else {
                defaults.removeObject(forKey: Constants.paymentsSelectedPaymentMethod)
            }

            defaults.synchronize()
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
