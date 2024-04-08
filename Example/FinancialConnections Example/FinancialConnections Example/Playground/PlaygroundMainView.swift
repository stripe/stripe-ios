//
//  PlaygroundMainView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14.0, *)
struct PlaygroundMainView: View { // Rename to PlaygroundView

    @StateObject var viewModel = PlaygroundMainViewModel()

    var body: some View {
        ZStack {
            VStack {
                Form {
                    Section(header: Text("Select SDK Type")) {
                        VStack(alignment: .leading, spacing: 4) {
//                            Text("Select SDK Type")
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
                        } else if viewModel.merchant.wrappedValue.customId == "custom-keys" {
                            TextField("Public Key (pk_)", text: viewModel.customPublicKey)
                            TextField("Secret Key (sk_)", text: viewModel.customSecretKey)
                        }
                    }

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

                    Section(header: Text("Customer")) {
                        TextField("Email (ex. existing Link consumer)", text: viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .accessibility(identifier: "playground-email")
                    }

                    // (enable step-up verification)
                    Section(header: Text("PERMISSIONS")) {
                        Toggle("Balances", isOn: $viewModel.enableBalancesPermission)
                            .accessibility(identifier: "playground-balances-permission")

                        Toggle("Ownership", isOn: $viewModel.enableOwnershipPermission)
                            .accessibility(identifier: "playground-ownership-permission")

                        Toggle("Payment Method", isOn: .constant(false))
                            .accessibility(identifier: "playground-payment-method-permission")

                        Toggle("Transactions", isOn: $viewModel.enableTransactionsPermission)
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
