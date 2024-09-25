//
//  OnboardingSettings.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/20/24.
//

import SwiftUI

struct OnboardingSettingsView: View {

    @Environment(\.dismiss) var dismiss

    @Binding var onboardingSettings: OnboardingSettings

    var saveEnabled: Bool {
        AppSettings.shared.onboardingSettings != onboardingSettings
        && isValidURL(onboardingSettings.fullTermsOfServiceString)
        && isValidURL(onboardingSettings.recipientTermsOfServiceString)
        && isValidURL( onboardingSettings.privacyPolicyString)
    }

    var body: some View {
        List {
            Section {
                TextInput(label: "Full terms of service", placeholder: "https://example.com", text: $onboardingSettings.fullTermsOfServiceString, isValid: isValidURL(onboardingSettings.fullTermsOfServiceString))
                TextInput(label: "Recipient terms of service", placeholder: "https://example.com", text: $onboardingSettings.recipientTermsOfServiceString, isValid: isValidURL(onboardingSettings.recipientTermsOfServiceString))
                TextInput(label: "Privacy policy", placeholder: "https://example.com", text: $onboardingSettings.privacyPolicyString, isValid: isValidURL( onboardingSettings.privacyPolicyString))

                Picker("Skip terms of service", selection: $onboardingSettings.skipTermsOfService) {
                    ForEach(OnboardingSettings.ToggleOption.allCases) { option in
                        Text(option.displayLabel)
                            .tag(option)
                    }
                }

                Picker("Field option", selection: $onboardingSettings.fieldOption) {
                    ForEach(OnboardingSettings.FieldOption.allCases) { option in
                        Text(option.displayLabel)
                            .tag(option)
                    }
                }

                Picker("Future requirements", selection: $onboardingSettings.futureRequirement) {
                    ForEach(OnboardingSettings.FutureRequirement.allCases) { option in
                        Text(option.displayLabel)
                            .tag(option)
                    }
                }

                Button {
                    onboardingSettings = .init()
                    AppSettings.shared.onboardingSettings = onboardingSettings
                } label: {
                    Text("Reset to defaults")
                }
            } header: {
            }
            .textInputAutocapitalization(.never)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Onboarding Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    AppSettings.shared.onboardingSettings = onboardingSettings
                    dismiss()
                } label: {
                    Text("Save")
                }
                .disabled(!saveEnabled)
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }

    func isValidURL(_ url: String) -> Bool {
        URL(string: url)?.isValid == true || url.isEmpty
    }
}
