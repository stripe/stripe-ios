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

        // MARK: Custom Theme
        static let formPlaceholderTextColor = "FormPlaceholderTextColor"
        static let inputFieldPaddingX = "InputFieldPaddingX"
        static let inputFieldPaddingY = "InputFieldPaddingY"
        static let actionPrimaryTextTransform = "ActionPrimaryTextTransform"
        static let actionSecondaryTextTransform = "ActionSecondaryTextTransform"
        static let tableRowPaddingY = "TableRowPaddingY"
        static let buttonDangerColorBackground = "ButtonDangerColorBackground"
        static let buttonDangerColorBorder = "ButtonDangerColorBorder"
        static let buttonDangerColorText = "ButtonDangerColorText"
        static let badgeWarningColorBackground = "BadgeWarningColorBackground"
        static let badgeWarningColorBorder = "BadgeWarningColorBorder"
        static let badgeWarningColorText = "BadgeWarningColorText"
        static let badgeLabelTextTransform = "BadgeLabelTextTransform"
        static let badgeLabelFontWeight = "BadgeLabelFontWeight"
        static let badgeLabelFontSize = "BadgeLabelFontSize"
        static let badgePaddingY = "BadgePaddingY"
        static let badgePaddingX = "BadgePaddingX"
        static let buttonLabelTextTransform = "ButtonLabelTextTransform"
        static let buttonLabelFontWeight = "ButtonLabelFontWeight"
        static let buttonLabelFontSize = "ButtonLabelFontSize"
        static let buttonPaddingY = "ButtonPaddingY"
        static let buttonPaddingX = "ButtonPaddingX"
        static let spacingUnit = "SpacingUnit"
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

    // MARK: - Custom Theme Values

    var formPlaceholderTextColor: String {
        get { defaults.string(forKey: Constants.formPlaceholderTextColor) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.formPlaceholderTextColor) }
    }

    var inputFieldPaddingX: String {
        get { defaults.string(forKey: Constants.inputFieldPaddingX) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.inputFieldPaddingX) }
    }

    var inputFieldPaddingY: String {
        get { defaults.string(forKey: Constants.inputFieldPaddingY) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.inputFieldPaddingY) }
    }

    var actionPrimaryTextTransform: String {
        get { defaults.string(forKey: Constants.actionPrimaryTextTransform) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.actionPrimaryTextTransform) }
    }

    var actionSecondaryTextTransform: String {
        get { defaults.string(forKey: Constants.actionSecondaryTextTransform) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.actionSecondaryTextTransform) }
    }

    var tableRowPaddingY: String {
        get { defaults.string(forKey: Constants.tableRowPaddingY) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.tableRowPaddingY) }
    }

    var buttonDangerColorBackground: String {
        get { defaults.string(forKey: Constants.buttonDangerColorBackground) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonDangerColorBackground) }
    }

    var buttonDangerColorBorder: String {
        get { defaults.string(forKey: Constants.buttonDangerColorBorder) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonDangerColorBorder) }
    }

    var buttonDangerColorText: String {
        get { defaults.string(forKey: Constants.buttonDangerColorText) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonDangerColorText) }
    }

    var badgeWarningColorBackground: String {
        get { defaults.string(forKey: Constants.badgeWarningColorBackground) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgeWarningColorBackground) }
    }

    var badgeWarningColorBorder: String {
        get { defaults.string(forKey: Constants.badgeWarningColorBorder) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgeWarningColorBorder) }
    }

    var badgeWarningColorText: String {
        get { defaults.string(forKey: Constants.badgeWarningColorText) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgeWarningColorText) }
    }

    var badgeLabelTextTransform: String {
        get { defaults.string(forKey: Constants.badgeLabelTextTransform) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgeLabelTextTransform) }
    }

    var badgeLabelFontWeight: String {
        get { defaults.string(forKey: Constants.badgeLabelFontWeight) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgeLabelFontWeight) }
    }

    var badgeLabelFontSize: String {
        get { defaults.string(forKey: Constants.badgeLabelFontSize) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgeLabelFontSize) }
    }

    var badgePaddingY: String {
        get { defaults.string(forKey: Constants.badgePaddingY) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgePaddingY) }
    }

    var badgePaddingX: String {
        get { defaults.string(forKey: Constants.badgePaddingX) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.badgePaddingX) }
    }

    var buttonLabelTextTransform: String {
        get { defaults.string(forKey: Constants.buttonLabelTextTransform) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonLabelTextTransform) }
    }

    var buttonLabelFontWeight: String {
        get { defaults.string(forKey: Constants.buttonLabelFontWeight) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonLabelFontWeight) }
    }

    var buttonLabelFontSize: String {
        get { defaults.string(forKey: Constants.buttonLabelFontSize) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonLabelFontSize) }
    }

    var buttonPaddingY: String {
        get { defaults.string(forKey: Constants.buttonPaddingY) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonPaddingY) }
    }

    var buttonPaddingX: String {
        get { defaults.string(forKey: Constants.buttonPaddingX) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.buttonPaddingX) }
    }

    var spacingUnit: String {
        get { defaults.string(forKey: Constants.spacingUnit) ?? "" }
        set { defaults.setValue(newValue, forKey: Constants.spacingUnit) }
    }

    /// Clears all custom theme values
    func clearCustomThemeValues() {
        formPlaceholderTextColor = ""
        inputFieldPaddingX = ""
        inputFieldPaddingY = ""
        actionPrimaryTextTransform = ""
        actionSecondaryTextTransform = ""
        tableRowPaddingY = ""
        buttonDangerColorBackground = ""
        buttonDangerColorBorder = ""
        buttonDangerColorText = ""
        badgeWarningColorBackground = ""
        badgeWarningColorBorder = ""
        badgeWarningColorText = ""
        badgeLabelTextTransform = ""
        badgeLabelFontWeight = ""
        badgeLabelFontSize = ""
        badgePaddingY = ""
        badgePaddingX = ""
        buttonLabelTextTransform = ""
        buttonLabelFontWeight = ""
        buttonLabelFontSize = ""
        buttonPaddingY = ""
        buttonPaddingX = ""
        spacingUnit = ""
    }
}

private extension UserDefaults {
    func string(forKey defaultName: String, defaultValue: String = "") -> String {
        self.string(forKey: defaultName) ?? defaultValue
    }
}
