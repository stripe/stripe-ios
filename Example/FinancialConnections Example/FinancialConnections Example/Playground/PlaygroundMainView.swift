//
//  PlaygroundMainView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SwiftUI

struct PlaygroundMainView: View {

    @StateObject var viewModel = PlaygroundMainViewModel()

    var body: some View {
        ZStack {
            VStack {
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("What do you want to use Financial Connections for?")
                                .font(.headline)
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

                        VStack(alignment: .leading, spacing: 4) {
                            Text("How do you want it to look like?")
                                .font(.headline)
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

                        if !viewModel.enableAppToApp
                            && (viewModel.customPublicKey.isEmpty || viewModel.customSecretKey.isEmpty)
                        {
                            if #available(iOS 14.0, *) {
                                Toggle("Enable Test Mode", isOn: $viewModel.enableTestMode)
                                    // test mode color
                                    .toggleStyle(
                                        SwitchToggleStyle(
                                            tint: Color(red: 231 / 255.0, green: 151 / 255.0, blue: 104 / 255.0)
                                        )
                                    )
                            } else {
                                Toggle("Enable Test Mode", isOn: $viewModel.enableTestMode)
                            }
                        }

                        if viewModel.customPublicKey.isEmpty || viewModel.customSecretKey.isEmpty {
                            Toggle("Enable App To App (livemode only)", isOn: $viewModel.enableAppToApp)
                        }

                        Button(action: viewModel.didSelectClearCaches) {
                            Text("Clear Caches")
                        }
                    }

                    Section(header: Text("CUSTOM KEYS")) {
                        TextField("Public Key (pk_)", text: $viewModel.customPublicKey)
                        TextField("Secret Key (sk_)", text: $viewModel.customSecretKey)
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
                    if #available(iOS 14.0, *) {
                        ProgressView()
                            .scaleEffect(2.0)
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
}

struct PlaygroundMainView_Previews: PreviewProvider {
    static var previews: some View {
        PlaygroundMainView()
    }
}
