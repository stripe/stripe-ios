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
    @State var showingQRSheet = false

    init(settings: PaymentSheetTestPlaygroundSettings) {
        _playgroundController = StateObject(wrappedValue: PlaygroundController(settings: settings))
    }

    @ViewBuilder
    var clientSettings: some View {
        // Note: Use group to work around XCode 14: "Extra Argument in Call" issue
        //  (each view can hold 10 direct subviews)
        Group {
            SettingView(setting: uiStyle)
            SettingView(setting: $playgroundController.settings.shippingInfo)
            SettingView(setting: $playgroundController.settings.applePayEnabled)
            SettingView(setting: $playgroundController.settings.applePayButtonType)
            SettingView(setting: $playgroundController.settings.allowsDelayedPMs)
            SettingView(setting: $playgroundController.settings.defaultBillingAddress)
            SettingView(setting: $playgroundController.settings.linkEnabled)
            SettingView(setting: $playgroundController.settings.linkV2Allowed)
            SettingView(setting: $playgroundController.settings.externalPayPalEnabled)
            SettingView(setting: $playgroundController.settings.preferredNetworksEnabled)
        }
        Group {
            if playgroundController.settings.uiStyle == .flowController {
                if playgroundController.settings.integrationType == .deferred_csc {
                    SettingView(setting: $playgroundController.settings.requireCVCRecollection)
                }
            }
        }
        Group {
            SettingView(setting: $playgroundController.settings.autoreload)
        }
    }

    var uiStyle: Binding<PaymentSheetTestPlaygroundSettings.UIStyle> {
        Binding<PaymentSheetTestPlaygroundSettings.UIStyle> {
            return playgroundController.settings.uiStyle
        } set: { newValue in
            if newValue != .flowController {
                playgroundController.settings.requireCVCRecollection = .off
            }
            playgroundController.settings.uiStyle = newValue
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
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                            Button {
                                playgroundController.didTapEndpointConfiguration()
                            } label: {
                                Text("Endpoints")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                            Button {
                                showingQRSheet.toggle()
                            } label: {
                                Text("QR")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                                .sheet(isPresented: $showingQRSheet, content: {
                                    QRView(url: playgroundController.settings.base64URL)
                                })
                        }
                        SettingView(setting: $playgroundController.settings.mode)
                        SettingPickerView(setting: integrationType)
                        SettingView(setting: customerModeBinding)
                        TextField("CustomerId", text: customerIdBinding)
                            .disabled(true)
                        SettingPickerView(setting: $playgroundController.settings.currency)
                        SettingPickerView(setting: merchantCountryBinding)
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
                        clientSettings
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

    var integrationType: Binding<PaymentSheetTestPlaygroundSettings.IntegrationType> {
        Binding<PaymentSheetTestPlaygroundSettings.IntegrationType> {
            return playgroundController.settings.integrationType
        } set: { newValue in
            if newValue != .deferred_csc {
                playgroundController.settings.requireCVCRecollection = .off
            }
            playgroundController.settings.integrationType = newValue
        }
    }

    var customCTABinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customCtaLabel ?? ""
        } set: { newString in
            playgroundController.settings.customCtaLabel = (newString != "") ? newString : nil
        }
    }
    var customerModeBinding: Binding<PaymentSheetTestPlaygroundSettings.CustomerMode> {
        Binding<PaymentSheetTestPlaygroundSettings.CustomerMode> {
            return playgroundController.settings.customerMode
        } set: { newMode in
            playgroundController.settings.customerId = nil
            playgroundController.settings.customerMode = newMode
        }
    }
    var customerIdBinding: Binding<String> {
        Binding<String> {
            switch playgroundController.settings.customerMode {
            case .guest:
                return ""
            case .new:
                return playgroundController.settings.customerId ?? ""
            case .returning:
                return playgroundController.settings.customerId ?? ""
            }
        } set: { newString in
            playgroundController.settings.customerId = (newString != "") ? newString : nil
        }
    }
    var merchantCountryBinding: Binding<PaymentSheetTestPlaygroundSettings.MerchantCountry> {
        Binding<PaymentSheetTestPlaygroundSettings.MerchantCountry> {
            return playgroundController.settings.merchantCountryCode
        } set: { newCountry in
            // Reset customer id if country changes
            if playgroundController.settings.merchantCountryCode.rawValue != newCountry.rawValue {
                playgroundController.settings.customerMode = .guest
            }
            playgroundController.settings.merchantCountryCode = newCountry
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
                            VStack {
                                Button {
                                    psFCOptionsIsPresented = true
                                } label: {
                                    PaymentOptionView(paymentOptionDisplayData: playgroundController.paymentSheetFlowController?.paymentOption)
                                }
                                .disabled(playgroundController.paymentSheetFlowController == nil)
                                Button {
                                    psFCOptionsIsPresented = true
                                } label: {
                                    PaymentOptionInfoView(paymentOptionDisplayData: playgroundController.paymentSheetFlowController?.paymentOption)
                                }
                                .disabled(playgroundController.paymentSheetFlowController == nil)
                                .padding()
                            }
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
                .foregroundColor(.primary)
            }
        }
}

struct PaymentOptionInfoView: View {
    let paymentOptionDisplayData: PaymentSheet.FlowController.PaymentOptionDisplayData?

    var body: some View {
        VStack {
            if let paymentMethodType = paymentOptionDisplayData?.paymentMethodType {
                Text(paymentMethodType)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            if let billingDetails = paymentOptionDisplayData?.billingDetails {
                BillingDetailsView(billingDetails: billingDetails)
                    .font(.caption)
                    .foregroundColor(.primary)

            }
        }
    }
}

struct BillingDetailsView: View {
    let billingDetails: PaymentSheet.BillingDetails

    var body: some View {
        VStack {
            if let name = billingDetails.name {
                Text(name)
                    .accessibility(identifier: "Name")
            }
            if let email = billingDetails.email {
                Text(email)
                    .accessibility(identifier: "Email")
            }
            if let phone = billingDetails.phone {
                Text(phone)
                    .accessibility(identifier: "Phone")
            }
            if let line1 = billingDetails.address.line1 {
                Text(line1)
                    .accessibility(identifier: "Line1")
            }
            if let line2 = billingDetails.address.line2 {
                Text(line2)
                    .accessibility(identifier: "Line2")
            }
            if let city = billingDetails.address.city {
                Text(city)
                    .accessibility(identifier: "City")
            }
            if let state = billingDetails.address.state {
                Text(state)
                    .accessibility(identifier: "State")
            }
            if let postalCode = billingDetails.address.postalCode {
                Text(postalCode)
                    .accessibility(identifier: "PostalCode")
            }
            if let country = billingDetails.address.country {
                Text(country)
                    .accessibility(identifier: "Country")
            }
        }
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
