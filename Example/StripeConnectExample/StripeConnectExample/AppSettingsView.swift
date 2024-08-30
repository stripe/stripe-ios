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
    
    var isCustomEndpointValid: Bool {
        guard let url = URL(string: serverURLString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    var saveEnabled: Bool {
        isCustomEndpointValid &&
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
                } header: {
                    Text("Select a demo account")
                }
                Section {
                    TextInput(label: "", placeholder: "https://example.com", text: $serverURLString, isValid: isCustomEndpointValid)
                    Button {
                        serverURLString = AppSettings.Constants.defaultServerBaseURL
                    } label: {
                        Text("Reset to default")
                            .disabled(AppSettings.Constants.defaultServerBaseURL == serverURLString)
                    }
                } header: {
                    Text("API Server Settings")
                }
            }
            .listStyle(.insetGrouped)
            .animation(.easeOut(duration: 0.2), value: selectedMerchant)
            .navigationTitle("Configure server")
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
