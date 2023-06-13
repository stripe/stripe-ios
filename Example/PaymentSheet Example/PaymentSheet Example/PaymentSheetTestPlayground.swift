//
//  PaymentSheetTestPlayground.swift
//  PaymentSheet Example
//
//  Created by David Estes on 5/31/23.
//

import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct PaymentSheetTestPlayground: View {
    @StateObject var playgroundController: PlaygroundController

    init(settings: PaymentSheetTestPlaygroundSettings) {
        _playgroundController = StateObject(wrappedValue: PlaygroundController(settings: settings))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Group {
                        HStack {
                            Text("Backend")
                                .font(.headline)
                            Spacer()
                            Button {
                                playgroundController.didTapEndpointConfiguration()
                            } label: {
                                Text("Endpoints")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                            Button {
                                playgroundController.didTapResetConfig()
                            } label: {
                                Text("Reset")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                        }
                        SettingView(setting: $playgroundController.settings.mode)
                        SettingPickerView(setting: $playgroundController.settings.integrationType)
                        SettingView(setting: $playgroundController.settings.customerMode)
                        SettingView(setting: $playgroundController.settings.currency)
                        SettingView(setting: $playgroundController.settings.merchantCountryCode)
                        SettingView(setting: $playgroundController.settings.apmsEnabled)
                    }
                    Divider()
                    Group {
                        HStack {
                            Text("Client")
                                .font(.headline)
                            Spacer()
                            Button {
                                playgroundController.appearanceButtonTapped()
                            } label: {
                                Text("Appearance")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                        }
                        SettingView(setting: $playgroundController.settings.uiStyle)
                        SettingView(setting: $playgroundController.settings.shippingInfo)
                        SettingView(setting: $playgroundController.settings.applePayEnabled)
                        SettingView(setting: $playgroundController.settings.applePayButtonType)
                        SettingView(setting: $playgroundController.settings.allowsDelayedPMs)
                        SettingView(setting: $playgroundController.settings.defaultBillingAddress)
                        SettingView(setting: $playgroundController.settings.linkEnabled)
                        SettingView(setting: $playgroundController.settings.autoreload)
                        TextField("Custom CTA", text: customCTABinding)
                    }
                    Divider()
                    Group {
                        HStack {
                            Text("Billing Details Collection")
                                .font(.headline)
                            Spacer()
                        }
                        SettingView(setting: $playgroundController.settings.attachDefaults)
                        SettingView(setting: $playgroundController.settings.collectName)
                        SettingView(setting: $playgroundController.settings.collectEmail)
                        SettingView(setting: $playgroundController.settings.collectPhone)
                        SettingView(setting: $playgroundController.settings.collectAddress)
                    }
                }.padding()
            }
            Spacer()
            Divider()
            PaymentSheetButtons()
                .environmentObject(playgroundController)
        }
    }

    var customCTABinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customCtaLabel ?? ""
        } set: { newString in
            playgroundController.settings.customCtaLabel = (newString != "") ? newString : nil
        }

    }
}

@available(iOS 14.0, *)
struct PaymentSheetButtons: View {
    @EnvironmentObject var playgroundController: PlaygroundController
    @State var psIsPresented: Bool = false
    @State var psFCOptionsIsPresented: Bool = false
    @State var psFCIsConfirming: Bool = false

    func reloadPlaygroundController() {
        playgroundController.load()
    }

    var body: some View {
        VStack {
            if playgroundController.settings.uiStyle == .paymentSheet {
                VStack {
                    HStack {
                        Text("PaymentSheet")
                            .font(.subheadline.smallCaps())
                        Spacer()
                        if playgroundController.isLoading {
                            ProgressView()
                        } else {
                            if playgroundController.settings != playgroundController.currentlyRenderedSettings {
                                StaleView()
                            }
                            Button {
                                reloadPlaygroundController()
                            } label: {
                                Image(systemName: "arrow.clockwise.circle")
                            }
                            .accessibility(identifier: "Reload")
                            .frame(alignment: .topLeading)
                        }
                    }.padding(.horizontal)
                    if let ps = playgroundController.paymentSheet {
                        HStack {
                            Button {
                                psIsPresented = true
                            } label: {
                                Text("Present PaymentSheet")
                            }
                            .paymentSheet(isPresented: $psIsPresented, paymentSheet: ps, onCompletion: playgroundController.onPSCompletion)
                            Spacer()
                            Button {
                                playgroundController.didTapShippingAddressButton()
                            } label: {
                                Text("\(playgroundController.addressDetails?.localizedDescription ?? "Address")")
                                    .accessibility(identifier: "Address")
                            }
                        }
                        .padding()
                    } else {
                        Text("PaymentSheet is nil")
                        .foregroundColor(.gray)
                        .padding()
                    }
                    if let result = playgroundController.lastPaymentResult {
                        ExamplePaymentStatusView(result: result)
                    }
                }
            } else {
                VStack {
                    HStack {
                        Text("PaymentSheet.FlowController")
                            .font(.subheadline.smallCaps())
                        Spacer()
                        if playgroundController.isLoading {
                            ProgressView()
                        } else {
                            if playgroundController.settings != playgroundController.currentlyRenderedSettings {
                                StaleView()
                            }
                            Button {
                                reloadPlaygroundController()
                            } label: {
                                Image(systemName: "arrow.clockwise.circle")
                            }
                            .accessibility(identifier: "Reload")
                            .frame(alignment: .topLeading)
                        }
                    }.padding(.horizontal)
                    HStack {
                        if let psfc = playgroundController.paymentSheetFlowController {
                            Button {
                                psFCOptionsIsPresented = true
                            } label: {
                                PaymentOptionView(paymentOptionDisplayData: playgroundController.paymentSheetFlowController?.paymentOption)
                            }
                            .disabled(playgroundController.paymentSheetFlowController == nil)
                            .padding()
                            Button {
                                playgroundController.didTapShippingAddressButton()
                            } label: {
                                Text("\(playgroundController.addressDetails?.localizedDescription ?? "Address")")
                                    .accessibility(identifier: "Address")
                            }
                            .disabled(playgroundController.paymentSheetFlowController == nil)
                            .padding()
                            Button {
                                psFCIsConfirming = true
                            } label: {
                                Text("Confirm")
                            }
                            .paymentConfirmationSheet(isConfirming: $psFCIsConfirming, paymentSheetFlowController: psfc, onCompletion: playgroundController.onPSFCCompletion)
                            .paymentOptionsSheet(isPresented: $psFCOptionsIsPresented, paymentSheetFlowController: psfc, onSheetDismissed: playgroundController.onOptionsCompletion)
                            .padding()
                        } else {
                            Text("PaymentSheet is nil")
                            .foregroundColor(.gray)
                            .padding()
                        }
                    }
                    if let result = playgroundController.lastPaymentResult {
                        ExamplePaymentStatusView(result: result)
                    }
                }
            }
        }
    }
}

struct StaleView: View {
    var body: some View {
        Text("Stale")
            .font(.subheadline.smallCaps().bold())
            .padding(.horizontal, 4.0)
            .padding(.bottom, 2.0)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8.0)
    }
}

struct PaymentOptionView: View {
    let paymentOptionDisplayData: PaymentSheet.FlowController.PaymentOptionDisplayData?

    var body: some View {
        HStack {
            Image(uiImage: paymentOptionDisplayData?.image ?? UIImage(systemName: "creditcard")!)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 30, maxHeight: 30, alignment: .leading)
                .foregroundColor(.black)
            Text(paymentOptionDisplayData?.label ?? "None")
                // Surprisingly, setting the accessibility identifier on the HStack causes the identifier to be
                // "Payment method-Payment method". We'll set it on a single View instead.
                .accessibility(identifier: "Payment method")
        }
        .padding()
        .foregroundColor(.black)
        .cornerRadius(6)
    }
}

struct SettingView<S: PickerEnum>: View {
    var setting: Binding<S>

    var body: some View {
        HStack {
            Text(S.enumName).font(.subheadline)
            Picker(S.enumName, selection: setting) {
                ForEach(S.allCases, id: \.self) { t in
                    Text(t.displayName)
                }
            }.pickerStyle(.segmented)
        }
    }
}

struct SettingPickerView<S: PickerEnum>: View {
    var setting: Binding<S>

    var body: some View {
        HStack {
            Text(S.enumName).font(.subheadline)
            Spacer()
            Picker(S.enumName, selection: setting) {
                ForEach(S.allCases, id: \.self) { t in
                    Text(t.displayName)
                }
            }
        }
    }
}

@available(iOS 15.0, *)
struct PaymentSheetTestPlayground_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetTestPlayground(settings: .defaultValues())
    }
}
