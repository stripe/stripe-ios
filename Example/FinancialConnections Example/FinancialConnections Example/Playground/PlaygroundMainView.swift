//
//  PlaygroundMainView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct PlaygroundMainView: View {

    @StateObject var viewModel = PlaygroundMainViewModel()

    var body: some View {
        ZStack {
            VStack {
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select Mobile SDK Type")
                            Picker("Enable Native?", selection: $viewModel.nativeSelection) {
                                ForEach(PlaygroundMainViewModel.NativeSelection.allCases) {
                                    Text($0.rawValue.capitalized)
                                        .tag($0)
                                }
                            }
                            .pickerStyle(.segmented)
                            Text("'Automatic' will let the server choose between 'Web' or 'Native'.")
                                .font(.caption)
                                .italic()
                        }
                    }

                    Section {
                        Picker("Scenario", selection: $viewModel.customScenario) {
                            ForEach(PlaygroundMainViewModel.CustomScenario.allCases, id: \.self) {
                                Text($0.displayName)
                            }
                        }
                        .pickerStyle(.menu)

                        if viewModel.customScenario == .none {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Select Flow")
                                Picker("Flow?", selection: $viewModel.flow) {
                                    ForEach(PlaygroundMainViewModel.Flow.allCases) {
                                        Text($0.rawValue.capitalized)
                                            .tag($0)
                                    }
                                }
                                .pickerStyle(.segmented)
                                Text("'Payments' has manual entry enabled.")
                                    .font(.caption)
                                    .italic()
                            }

                            Toggle("Enable Test Mode", isOn: $viewModel.enableTestMode)
                            // test mode color
                                .toggleStyle(
                                    SwitchToggleStyle(
                                        tint: Color(red: 231 / 255.0, green: 151 / 255.0, blue: 104 / 255.0)
                                    )
                                )

                            if viewModel.flow == .networking {
                                TextField("Email (existing Link consumer)", text: $viewModel.email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .accessibility(identifier: "playground-email")

                                Toggle("Enable Multi Select", isOn: $viewModel.enableNetworkingMultiSelect)
                                    .accessibility(identifier: "networking-multi-select")
                            }
                        } else if viewModel.customScenario == .customKeys {
                            TextField("Public Key (pk_)", text: $viewModel.customPublicKey)
                            TextField("Secret Key (sk_)", text: $viewModel.customSecretKey)
                        }
                    }

                    Section(header: Text("PERMISSIONS")) {
                        Toggle("Ownership", isOn: $viewModel.enableOwnershipPermission)
                            .accessibility(identifier: "playground-ownership-permission")

                        Toggle("Balances", isOn: $viewModel.enableBalancesPermission)
                            .accessibility(identifier: "playground-balances-permission")

                        Toggle("Transactions \(viewModel.flow == .networking ? "(enable step-up verification)" : "")", isOn: $viewModel.enableTransactionsPermission)
                            .accessibility(identifier: "playground-transactions-permission")
                    }

                    Section {
                        Toggle("Show Live Events", isOn: $viewModel.showLiveEvents)

                        Button(action: viewModel.didSelectClearCaches) {
                            Text("Clear Cache (requests, images etc.)")
                        }
                    }

                    // extra space so keyboard doesn't cover the "CUSTOM KEYS" section
                    // (SwiftUI, depending on iOS version, doesn't handle keyboard)
                    Spacer(minLength: 60)
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
    }
}

@available(iOS 14.0, *)
struct PlaygroundMainView_Previews: PreviewProvider {
    static var previews: some View {
        PlaygroundMainView()
    }
}
