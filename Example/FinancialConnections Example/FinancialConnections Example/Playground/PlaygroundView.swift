//
//  PlaygroundView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct PlaygroundView: View {

    @StateObject var viewModel = PlaygroundViewModel()

    var body: some View {
        ZStack {
            VStack {
                Form {
                    Section(header: Text("Experience")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("Select Experience", selection: viewModel.experience) {
                                ForEach(PlaygroundConfiguration.Experience.allCases) {
                                    Text($0.displayName)
                                        .tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    Section(header: Text("Select SDK Type")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("Select SDK Type", selection: viewModel.sdkType) {
                                ForEach(PlaygroundConfiguration.SDKType.allCases) {
                                    Text($0.rawValue.capitalized)
                                        .tag($0)
                                }
                            }
                            .pickerStyle(.segmented)

                            if viewModel.sdkType.wrappedValue == .automatic {
                                Text("'Automatic' will let the server choose between 'Web' or 'Native'.")
                                    .font(.caption)
                                    .italic()
                            }
                        }
                    }

                    Section(header: Text("Merchant")) {
                        Picker("Merchant", selection: viewModel.merchant) {
                            ForEach(viewModel.playgroundConfiguration.merchants) {
                                Text($0.displayName)
                                    .tag($0)
                            }
                        }
                        .pickerStyle(.menu)

                        if viewModel.merchant.wrappedValue.isTestModeSupported {
                            Toggle("Enable Test Mode", isOn: viewModel.testMode)
                                .toggleStyle(
                                    SwitchToggleStyle(
                                        tint: Color(
                                            red: 231 / 255.0,
                                            green: 151 / 255.0,
                                            blue: 104 / 255.0
                                        )
                                    )
                                )
                        } else if viewModel.merchant.wrappedValue.customId == .customKeys {
                            TextField("Public Key (pk_)", text: viewModel.customPublicKey)
                            TextField("Secret Key (sk_)", text: viewModel.customSecretKey)
                        }
                    }

                    if viewModel.experience.wrappedValue == .financialConnections {
                        Section(header: Text("Select Use Case")) {
                            VStack(alignment: .leading, spacing: 4) {
                                Picker("Select Use Case", selection: viewModel.useCase) {
                                    ForEach(PlaygroundConfiguration.UseCase.allCases) {
                                        Text($0.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                                            .tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }

                    Section(header: Text(viewModel.useCase.wrappedValue == .token ? "Account" : "Customer")) {
                        TextField("Email (ex. existing Link consumer)", text: viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .accessibility(identifier: "playground-email")

                        if viewModel.useCase.wrappedValue != .token {
                            TextField("Phone", text: viewModel.phone)
                                .keyboardType(.phonePad)
                                .accessibility(identifier: "playground-phone")
                        }
                    }

                    Section(header: Text("PERMISSIONS")) {
                        Toggle("Balances", isOn: viewModel.balancesPermission)
                            .accessibility(identifier: "playground-balances-permission")

                        Toggle("Ownership", isOn: viewModel.ownershipPermission)
                            .accessibility(identifier: "playground-ownership-permission")

                        Toggle("Payment Method", isOn: viewModel.paymentMethodPermission)
                            .accessibility(identifier: "playground-payment-method-permission")

                        Toggle("Transactions", isOn: viewModel.transactionsPermission)
                            .accessibility(identifier: "playground-transactions-permission")
                    }

                    Section(header: Text("Other")) {
                        Toggle("Show Live Events", isOn: viewModel.liveEvents)

                        Button(action: viewModel.didSelectClearCaches) {
                            Text("Clear Cache (requests, images etc.)")
                        }

                        Button(
                            action: {
                                viewModel.showConfigurationView = true
                            }
                        ) {
                            Text("Manage Configuration")
                        }
                        .sheet(isPresented: $viewModel.showConfigurationView) {
                            NavigationView {
                                PlaygroundManageConfigurationView(
                                    viewModel: viewModel.playgroundConfigurationViewModel
                                )
                            }
                        }
                    }

                    Section(header: Text("Session output")) {
                        if let output = viewModel.sessionOutput[.message] {
                            TextEditor(text: .constant(output))
                                .accessibility(identifier: "playground-session-output-textfield")
                        }

                        Button(action: viewModel.copySessionId) {
                            Text("Copy Session ID")
                        }
                        .disabled(viewModel.sessionOutput[.sessionId] == nil)
                        .accessibility(identifier: "playground-session-output-copy-session-id")

                        Button(action: viewModel.copyAccountNames) {
                            Text("Copy Account Names")
                        }
                        .disabled(viewModel.sessionOutput[.accountNames] == nil)
                        .accessibility(identifier: "playground-session-output-copy-account-names")

                        Button(action: viewModel.copyAccountIds) {
                            Text("Copy Account IDs")
                        }
                        .disabled(viewModel.sessionOutput[.accountIds] == nil)
                        .accessibility(identifier: "playground-session-output-copy-account-ids")
                    }
                }

                VStack {
                    Button(action: viewModel.didSelectShow) {
                        VStack {
                            Text("Show Auth Flow")
                                .frame(maxWidth: .infinity)
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }.padding()
            }

            if viewModel.isLoading {
                ZStack {
                    Color(UIColor.systemGray)
                        .opacity(0.5)
                    ProgressView()
                        .scaleEffect(2.0)
                }
            } else {
                EmptyView()
            }
        }
        .navigationTitle("Playground")
        .navigationBarTitleDisplayMode(.inline)
        .gesture(DragGesture().onChanged(hideKeyboard))
        .animation(.easeIn(duration: 1), value: viewModel.experience.wrappedValue)
    }

    private func hideKeyboard(_ value: DragGesture.Value) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

@available(iOS 14.0, *)
struct PlaygroundView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlaygroundView()
        }
    }
}
