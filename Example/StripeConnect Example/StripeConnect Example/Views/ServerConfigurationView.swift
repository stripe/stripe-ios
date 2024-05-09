//
//  ServerConfigurationView.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 5/3/24.
//

import SwiftUI

/// A view to modify the configured server and account
struct ServerConfigurationView: View {
    @State var demoAccount: ServerConfiguration.DemoAccounts?
    @State var customAccount = ""
    @State var customEndpoint = ""
    @State var customPublishableKey = ""

    @Environment(\.dismiss) var dismiss

    let didSave: () -> Void

    init(configuration: ServerConfiguration = .shared,
         didSave: @escaping () -> Void = {}) {
        switch configuration {
        case .demo(let account):
            self._demoAccount = State(initialValue: account)
        case .customAccount(let account):
            self._customAccount = State(initialValue: account)
        case .customEndpoint(let endpoint, let publishableKey):
            self._customEndpoint = State(initialValue: endpoint.absoluteString)
            self._customPublishableKey = State(initialValue: publishableKey)
        }
        self.didSave = didSave
    }

    var isCustomPublishableKeyValid: Bool {
        customPublishableKey.hasPrefix("pk_") && customPublishableKey.count > 3
    }

    var isCustomEndpointValid: Bool {
        guard let url = URL(string: customEndpoint) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    var isCustomAccountValid: Bool {
        customAccount.hasPrefix("acct_") && customAccount.count > 5
    }

    var configuration: ServerConfiguration? {
        if isCustomAccountValid {
            return .customAccount(customAccount)
        }
        if let demoAccount {
            return .demo(demoAccount)
        }
        if let endpoint = URL(string: customEndpoint),
           isCustomPublishableKeyValid && isCustomEndpointValid {
            return .customEndpoint(endpoint, publishableKey: customPublishableKey)
        }
        return nil
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(ServerConfiguration.DemoAccounts.allCases, id: \.rawValue) { demoAccount in
                        Option(title: demoAccount.label,
                               subtitle: demoAccount.rawValue,
                               demoAccount: demoAccount,
                               selection: self.$demoAccount)
                    }
                } header: {
                    Text("Select a demo account")
                }

                Section {
                    VStack(spacing: 16) {
                        TextInput(label: Text("Enter a connected account for platform `\(ServerConfiguration.platformAccount)`"),
                                  placeholder: "acct_xxx",
                                  text: $customAccount,
                                  isValid: isCustomAccountValid)

                        Button(action: save) {
                            Text("Apply")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!isCustomAccountValid)
                        .buttonBorderShape(.capsule)
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Or another account")
                }

                Section {
                    VStack(spacing: 16) {
                        TextInput(label: "Client secret endpoint",
                                  placeholder: "https://{{SERVER}}/account_session",
                                  text: $customEndpoint,
                                  isValid: isCustomEndpointValid)
                        .keyboardType(.URL)

                        TextInput(label: "Publishable key",
                                  placeholder: "pk_xxx",
                                  text: $customPublishableKey,
                                  isValid: isCustomPublishableKeyValid)

                        Button(action: save) {
                            Text("Apply")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(!isCustomPublishableKeyValid || !isCustomEndpointValid)
                        .buttonBorderShape(.capsule)
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Or use your server")
                }
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .listStyle(.insetGrouped)
            .animation(.easeOut(duration: 0.2), value: demoAccount)
            .navigationTitle("Configure server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .onChange(of: demoAccount) { newValue in
                if newValue != nil {
                    customAccount = ""
                    customEndpoint = ""
                    customPublishableKey = ""
                    save()
                }
            }
            .onChange(of: customEndpoint) { newValue in
                if !newValue.isEmpty {
                    demoAccount = nil
                    customAccount = ""
                }
            }
            .onChange(of: customPublishableKey) { newValue in
                if !newValue.isEmpty {
                    demoAccount = nil
                    customAccount = ""
                }
            }
            .onChange(of: customAccount) { newValue in
                if !newValue.isEmpty {
                    demoAccount = nil
                    customEndpoint = ""
                    customPublishableKey = ""
                }
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }

    func save() {
        guard let configuration else { return }
        ServerConfiguration.shared = configuration
        dismiss()
        didSave()
    }

    struct Option: View {
        let title: String
        private(set) var subtitle: String?
        let demoAccount: ServerConfiguration.DemoAccounts?
        @Binding var selection: ServerConfiguration.DemoAccounts?

        var body: some View {
            Button {
                selection = demoAccount
            } label: {
                HStack {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .opacity(demoAccount == selection ? 1.0 : 0.0)
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.body)
                            .foregroundColor(Color(UIColor.label))
                        subtitle.map(Text.init)
                            .font(.caption)
                            .foregroundColor(Color(UIColor.secondaryLabel))
                    }
                }
            }
        }
    }
}

struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        ServerConfigurationView(configuration: .demo(.default))
    }
}
