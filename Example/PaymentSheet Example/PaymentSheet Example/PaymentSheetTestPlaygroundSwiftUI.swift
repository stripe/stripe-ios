//
//  PaymentSheetTestPlaygroundSwiftUI.swift
//  PaymentSheet Example
//
//  Created by David Estes on 5/31/23.
//

import SwiftUI
import StripePaymentSheet


@available(iOS 14.0, *)
struct PaymentSheetTestPlayground: View {
    @State var settings: PaymentSheetTestPlaygroundSettings
    @StateObject var playgroundController = PlaygroundController()
    
    var customCTABinding: Binding<String> {
        Binding<String> {
            return settings.customCtaLabel ?? ""
        } set: { newString in
            settings.customCtaLabel = (newString != "") ? newString : nil
        }

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
                                playgroundController.didTapResetConfig()
                            } label: {
                                Text("Reset")
                            }
                            Button {
                                playgroundController.didTapEndpointConfiguration()
                            } label: {
                                Text("Endpoints")
                            }
                            Button {
                                playgroundController.appearanceButtonTapped()
                            } label: {
                                Text("Appearance")
                            }
                        }
                        SettingView(setting: $settings.mode)
                        SettingView(setting: $settings.integrationType)
                        SettingView(setting: $settings.customerMode)
                        SettingView(setting: $settings.currency)
                        SettingView(setting: $settings.merchantCountryCode)
                        SettingView(setting: $settings.apmsEnabled)
                    }
                    Divider()
                    Group {
                        Text("Client")
                            .font(.headline)
                        SettingView(setting: $settings.shippingInfo)
                        SettingView(setting: $settings.applePayEnabled)
                        SettingView(setting: $settings.applePayButtonType)
                        SettingView(setting: $settings.allowsDelayedPMs)
                        SettingView(setting: $settings.defaultBillingAddress)
                        SettingView(setting: $settings.linkEnabled)
                        TextField("Custom CTA", text: customCTABinding)
                    }
                    Divider()
                    Group {
                        Text("Billing Details Collection (Alpha)")
                            .font(.headline)
                        SettingView(setting: $settings.attachDefaults)
                        SettingView(setting: $settings.collectName)
                        SettingView(setting: $settings.collectEmail)
                        SettingView(setting: $settings.collectPhone)
                        SettingView(setting: $settings.collectAddress)
                    }
                }.padding()
            }
            Spacer()
            Divider()
            PaymentSheetButtons()
                .environmentObject(playgroundController)
        }
    }
}

@available(iOS 14.0, *)
struct PaymentSheetButtons: View {
    @EnvironmentObject var playgroundController: PlaygroundController
    @State var psIsPresented: Bool = false
    @State var psFCOptionsIsPresented: Bool = false
    @State var psFCIsConfirming: Bool = false
    @State var paymentSheetResult: PaymentSheetResult?
    @State var psFCResult: PaymentSheetResult?
    
    func reloadPlaygroundController() {
        psFCResult = nil
        paymentSheetResult = nil
        playgroundController.load()
    }
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("PaymentSheet.FlowController")
                        .font(.subheadline.smallCaps())
                    Spacer()
                    if (playgroundController.isLoading) {
                        ProgressView()
                    } else {
                        Button {
                            reloadPlaygroundController()
                        } label: {
                            Image(systemName: "arrow.clockwise.circle")
                        }.frame(alignment: .topLeading)
                    }
                }.padding(.horizontal)
                HStack {
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
                    }
                    .disabled(playgroundController.paymentSheetFlowController == nil)
                    .padding()
                    if let psfc = playgroundController.paymentSheetFlowController {
                        Button {
                            psFCIsConfirming = true
                        } label: {
                            Text("Confirm")
                        }
                        .paymentConfirmationSheet(isConfirming: $psFCIsConfirming, paymentSheetFlowController: psfc, onCompletion: { result in
                            psFCResult = result
                        })
                        .paymentOptionsSheet(isPresented: $psFCOptionsIsPresented, paymentSheetFlowController: psfc) {
                            // No action when the payment options sheet is dismissed
                        }
                        .padding()
                    } else {
                        Text("Not loaded")
                        .padding()
                    }
                }
                if let result = psFCResult {
                    ExamplePaymentStatusView(result: result)
                }
            }
            Divider()
            VStack {
                HStack {
                    Text("PaymentSheet")
                        .font(.subheadline.smallCaps())
                    Spacer()
                    if (playgroundController.isLoading) {
                        ProgressView()
                    } else {
                        Button {
                            reloadPlaygroundController()
                        } label: {
                            Image(systemName: "arrow.clockwise.circle")
                        }.frame(alignment: .topLeading)
                    }
                }.padding(.horizontal)
                if let ps = playgroundController.paymentSheet {
                    Button {
                        psIsPresented = true
                    } label: {
                        Text("Present PaymentSheet")
                    }
                    .padding()
                    .paymentSheet(isPresented: $psIsPresented, paymentSheet: ps, onCompletion: { result in
                        paymentSheetResult = result
                    })
                } else {
                    Text("Not loaded")
                }
                if let result = paymentSheetResult {
                    ExamplePaymentStatusView(result: result)
                }
            }
        }.onAppear {
            playgroundController.load()
        }
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
            Text(paymentOptionDisplayData?.label ?? "Payment method")
                // Surprisingly, setting the accessibility identifier on the HStack causes the identifier to be
                // "Payment method-Payment method". We'll set it on a single View instead.
                .accessibility(identifier: "Payment method")
        }
        .padding()
        .foregroundColor(.black)
        .cornerRadius(6)
    }
}

protocol PickerEnum : Codable, CaseIterable, Identifiable, Hashable where AllCases: RandomAccessCollection {
    static var enumName: String { get }
    var displayName: String { get }
}

extension PickerEnum {
    var id: Self { self }
}

extension RawRepresentable where RawValue == String {
    var displayName: String { self.rawValue }
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

@available(iOS 14.0, *)
struct PaymentSheetTestPlayground_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetTestPlayground(settings: PaymentSheetTestPlaygroundSettings.defaultValues())
    }
}
