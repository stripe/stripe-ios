//
//  AccountOnboardingConfigurationView.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/3/24.
//

import StripeConnect
import SwiftUI

struct AccountOnboardingConfigurationView: View {

    let accountOnboardingViewController: AccountOnboardingViewController?

    @State var fullTermsOfService: String = ""
    @State var recipientTermsOfService: String = ""
    @State var privacyPolicy: String = ""
    @State var skipTermsOfService = false
    @State var eventuallyDue = false
    @State var futureRequirements = false

    @Environment(\.dismiss) var dismiss

    var collectionOptions: AccountOnboardingViewController.CollectionOptions {
        var options = AccountOnboardingViewController.CollectionOptions()
        options.futureRequirements = futureRequirements ? .include : .omit
        options.fields = eventuallyDue ? .eventuallyDue : .currentlyDue
        return options
    }

    var body: some View {
        NavigationView {
            List {
                TextInput(label: "Full terms of service",
                          placeholder: "https://www.example.com/tos",
                          text: $fullTermsOfService)
                TextInput(label: "Recipient terms of service",
                          placeholder: "https://www.example.com/recipient-tos",
                          text: $recipientTermsOfService)
                TextInput(label: "Privacy policy",
                          placeholder: "https://www.example.com/privacy-policy",
                          text: $privacyPolicy)
                Toggle(isOn: $skipTermsOfService) {
                    Text("Skip terms of service")
                }
                Toggle(isOn: $eventuallyDue) {
                    Text("Include eventually due")
                }
                Toggle(isOn: $futureRequirements) {
                    Text("Include future requirements")
                }
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .listStyle(.plain)
            .navigationTitle("Configure account onboarding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                    }
                }
            }
        }
        .onChange(of: fullTermsOfService) { newValue in
            if let url = URL(string: newValue),
               UIApplication.shared.canOpenURL(url)
            {
                accountOnboardingViewController?.setFullTermsOfServiceUrl(url)
            }
        }
        .onChange(of: recipientTermsOfService) { newValue in
            if let url = URL(string: newValue),
               UIApplication.shared.canOpenURL(url) {
                accountOnboardingViewController?.setRecipientTermsOfServiceUrl(url)
            }
        }
        .onChange(of: privacyPolicy) { newValue in
            if let url = URL(string: newValue),
               UIApplication.shared.canOpenURL(url) {
                accountOnboardingViewController?.setPrivacyPolicyUrl(url)
            }
        }
        .onChange(of: skipTermsOfService) { newValue in
            accountOnboardingViewController?.setSkipTermsOfServiceCollection(newValue)
        }
        .onChange(of: eventuallyDue) { _ in
            accountOnboardingViewController?.setCollectionOptions(collectionOptions)
        }
        .onChange(of: futureRequirements) { _ in
            accountOnboardingViewController?.setCollectionOptions(collectionOptions)
        }
    }
}

struct AccountOnboardingConfigurationView_Preview: PreviewProvider {
    static var previews: some View {
        AccountOnboardingConfigurationView(accountOnboardingViewController: nil)
    }
}
