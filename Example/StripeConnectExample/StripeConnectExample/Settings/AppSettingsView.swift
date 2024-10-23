//
//  ServerSettingsView.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 8/26/24.
//

import SwiftUI

struct AppSettingsView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.viewControllerPresenter) var viewControllerPresenter

    // App info is sometimes nil, if for example it fails to load.
    var appInfo: AppInfo?

    @State var selectedMerchant: MerchantInfo?
    @State var serverURLString: String = AppSettings.shared.selectedServerBaseURL
    @State var onboardingSettings = AppSettings.shared.onboardingSettings
    @State var presentationSettings = AppSettings.shared.presentationSettings

    var isCustomEndpointValid: Bool {
        URL(string: serverURLString)?.isValid == true
    }

    var isUsingCustomMerchant: Bool {
        guard let selectedMerchant,
              let appInfo else {
            return true
        }
        return !appInfo.availableMerchants.contains(selectedMerchant)
    }

    var isMerchantIdValid: Bool {
        if !isUsingCustomMerchant {
            return true
        } else if let selectedMerchant {
            return selectedMerchant.id.starts(with: "acct_")
            && selectedMerchant.id.count > 5
        } else {
            return false
        }
    }

    func isMerchantIdValid(_ id: String) -> Bool {
        id.starts(with: "acct_") && id.count > 5
    }

    var saveEnabled: Bool {
        isCustomEndpointValid &&
        isMerchantIdValid &&
        (AppSettings.shared.selectedMerchant(appInfo: appInfo)?.id != selectedMerchant?.id ||
         AppSettings.shared.selectedServerBaseURL != serverURLString)
    }

    init(appInfo: AppInfo?) {
        self.appInfo = appInfo
        _selectedMerchant = .init(initialValue: AppSettings.shared.selectedMerchant(appInfo: appInfo))
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach((appInfo?.availableMerchants ?? [])) { merchant in
                        OptionListRow(title: merchant.displayName ?? "",
                                      subtitle: merchant.id,
                                      selected: selectedMerchant?.id == merchant.id,
                                      onSelected: {
                            selectedMerchant = merchant
                        })
                    }
                    HStack {
                        TextInput(label: "Other",
                                  placeholder: "acct_xxxx",
                                  text: .init(
                                    get: {
                                        guard let selectedMerchant,
                                              isUsingCustomMerchant else {
                                            return ""
                                        }
                                        return selectedMerchant.id
                                    },
                                    set: {
                                        selectedMerchant = .init(displayName: nil, merchantId: $0)
                                    }
                                  ),
                                  isValid: isMerchantIdValid)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                            .opacity(isUsingCustomMerchant ? 1.0 : 0.0)
                    }
                } header: {
                    Text("Select a demo account")
                }
                Section {
                    NavigationLink {
                        OnboardingSettingsView(onboardingSettings: $onboardingSettings)
                    } label: {
                        Text("Account onboarding")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Component Settings")
                }

                NavigationLink {
                    PresentationSettingsView(presentationSettings: $presentationSettings)
                } label: {
                    Text("View Controller Options")
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Section {
                    TextInput(label: "", placeholder: "https://example.com", text: $serverURLString, isValid: isCustomEndpointValid)
                    Button {
                        serverURLString = AppSettings.Constants.defaultServerBaseURL
                    } label: {
                        Text("Reset to default")
                            .disabled(AppSettings.Constants.defaultServerBaseURL == serverURLString)
                            .keyboardType(.URL)
                    }
                } header: {
                    Text("API Server Settings")
                }
            }
            .listStyle(.insetGrouped)
            .animation(.easeOut(duration: 0.2), value: selectedMerchant)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        AppSettings.shared.setSelectedMerchant(merchant: selectedMerchant)
                        AppSettings.shared.selectedServerBaseURL = serverURLString
                        viewControllerPresenter?.setRootViewController(AppLoadingView().containerViewController)
                    } label: {
                        Text("Save")
                    }
                    .disabled(!saveEnabled)
                }
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }
}
