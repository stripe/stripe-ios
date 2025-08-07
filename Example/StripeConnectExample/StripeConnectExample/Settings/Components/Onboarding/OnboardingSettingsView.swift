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

                Picker("Requirements", selection: $onboardingSettings.requirementsOption) {
                    ForEach(OnboardingSettings.RequirementsOption.allCases) { option in
                        Text(option.displayLabel)
                            .tag(option)
                    }
                }

                if onboardingSettings.requirementsOption != .default {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Requirements List")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Enter one requirement per line")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        TextEditor(text: $onboardingSettings.requirementsString)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .font(.system(.body, design: .monospaced))
                    }
                    .padding(.vertical, 4)
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
