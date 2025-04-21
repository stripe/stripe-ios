//
//  OnboardingSettings.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/20/24.
//

import Foundation
@_spi(PrivateBetaConnect) import StripeConnect

struct OnboardingSettings: Equatable {
    var fullTermsOfServiceString: String = ""

    var fullTermsOfServiceUrl: URL? {
        !fullTermsOfServiceString.isEmpty ? URL(string: fullTermsOfServiceString) : nil
    }

    var recipientTermsOfServiceString: String = ""
    var recipientTermsOfServiceUrl: URL? {
        !recipientTermsOfServiceString.isEmpty ? URL(string: recipientTermsOfServiceString) : nil
    }

    var privacyPolicyString: String = ""
    var privacyPolicyUrl: URL? {
        !privacyPolicyString.isEmpty ? URL(string: privacyPolicyString) : nil
    }

    var skipTermsOfService: ToggleOption = .default
    var fieldOption: FieldOption = .default
    var futureRequirement: FutureRequirement = .default

    var accountCollectionOptions: AccountCollectionOptions {
        var accountCollectionOptions: AccountCollectionOptions = .init()
        switch fieldOption {
        case .default:
            // Default set nothing
            break
        case .currentlyDue:
            accountCollectionOptions.fields = .currentlyDue
        case .eventuallyDue:
            accountCollectionOptions.fields = .eventuallyDue
        }

        switch futureRequirement {
        case .default:
            // Default set nothing
            break
        case .omit:
            accountCollectionOptions.futureRequirements = .omit
        case .include:
            accountCollectionOptions.futureRequirements = .include
        }

        return accountCollectionOptions
    }

    enum FutureRequirement: String, CaseIterable, Identifiable {
        var id: String {
            self.rawValue
        }

        case `default`
        case omit
        case include

        var displayLabel: String {
            switch self {
            case .default:
                return "Default"
            case .omit:
                return "Omit"
            case .include:
                return "Include"
            }
        }
    }

    enum FieldOption: String, CaseIterable, Identifiable {
        var id: String {
            self.rawValue
        }

        case `default`
        case currentlyDue
        case eventuallyDue

        var displayLabel: String {
            switch self {
            case .default:
                return "Default"
            case .currentlyDue:
                return "Currently due"
            case .eventuallyDue:
                return "Eventually due"
            }
        }
    }

    enum ToggleOption: String, CaseIterable, Identifiable {
        var id: String {
            self.rawValue
        }

        case `default`
        case `false`
        case `true`

        var displayLabel: String {
            switch self {
            case .default:
                return "Default"
            case .false:
                return "False"
            case .true:
                return "True"
            }
        }

        var boolValue: Bool? {
            switch self {
            case .default:
                return nil
            case .false:
                return false
            case .true:
                return true
            }
        }

    }
}
