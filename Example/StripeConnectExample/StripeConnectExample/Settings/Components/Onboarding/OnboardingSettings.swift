//
//  OnboardingSettings.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/20/24.
//

import Foundation
import StripeConnect

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
    var requirementsOption: RequirementsOption = .default
    var requirementsString: String = ""

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

        // Configure requirements
        switch requirementsOption {
        case .default:
            // Default set nothing
            break
        case .only:
            let requirements = parseRequirementsString()
            if !requirements.isEmpty {
                accountCollectionOptions.requirements = .only(requirements)
            }
        case .exclude:
            let requirements = parseRequirementsString()
            if !requirements.isEmpty {
                accountCollectionOptions.requirements = .exclude(requirements)
            }
        }

        return accountCollectionOptions
    }

    private func parseRequirementsString() -> [String] {
        guard !requirementsString.isEmpty else { return [] }
        return requirementsString
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    enum RequirementsOption: String, CaseIterable, Identifiable {
        var id: String {
            self.rawValue
        }

        case `default`
        case only
        case exclude

        var displayLabel: String {
            switch self {
            case .default:
                return "Default"
            case .only:
                return "Only"
            case .exclude:
                return "Exclude"
            }
        }
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
