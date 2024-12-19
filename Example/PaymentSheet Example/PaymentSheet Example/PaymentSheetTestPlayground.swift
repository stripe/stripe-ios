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
    @StateObject var analyticsLogObserver: AnalyticsLogObserver = .shared
    @State var showingQRSheet = false

    init(settings: PaymentSheetTestPlaygroundSettings) {
        _playgroundController = StateObject(wrappedValue: PlaygroundController(settings: settings))
    }

    @ViewBuilder
    var clientSettings: some View {
        SettingView(setting: uiStyleBinding)
        if playgroundController.settings.uiStyle != .embedded {
            SettingView(setting: $playgroundController.settings.layout)
        }
        SettingView(setting: $playgroundController.settings.shippingInfo)
        SettingView(setting: $playgroundController.settings.applePayEnabled)
        SettingView(setting: $playgroundController.settings.applePayButtonType)
        SettingView(setting: $playgroundController.settings.allowsDelayedPMs)
        SettingPickerView(setting: $playgroundController.settings.defaultBillingAddress)
        if playgroundController.settings.defaultBillingAddress == .customEmail {
            TextField("Default email", text: customEmailBinding)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        }
        Group {
            if playgroundController.settings.merchantCountryCode == .US {
                SettingView(setting: $playgroundController.settings.linkEnabledMode)
            }
            SettingView(setting: $playgroundController.settings.linkPassthroughMode)
        }
        SettingView(setting: $playgroundController.settings.userOverrideCountry)
        SettingView(setting: $playgroundController.settings.externalPaymentMethods)
        SettingView(setting: $playgroundController.settings.preferredNetworksEnabled)
        SettingView(setting: $playgroundController.settings.cardBrandAcceptance)
        SettingView(setting: $playgroundController.settings.allowsRemovalOfLastSavedPaymentMethod)
        SettingView(setting: $playgroundController.settings.requireCVCRecollection)
        SettingView(setting: $playgroundController.settings.autoreload)
        SettingView(setting: $playgroundController.settings.shakeAmbiguousViews)
        SettingView(setting: $playgroundController.settings.instantDebitsIncentives)
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Group {
                        HStack {
                            if ProcessInfo.processInfo.environment["UITesting"] != nil {
                                AnalyticsLogForTesting(analyticsLog: $analyticsLogObserver.analyticsLog)
                            }
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
                        SettingPickerView(
                            setting: integrationTypeBinding,
                            disabledSettings: playgroundController.settings.uiStyle == .embedded ? [.normal] : []
                        )
                        SettingView(setting: $playgroundController.settings.customerKeyType)
                        SettingView(setting: customerModeBinding)
                        HStack {
                            SettingPickerView(setting: $playgroundController.settings.amount)
                            SettingPickerView(setting: $playgroundController.settings.currency)
                        }
                        SettingPickerView(setting: merchantCountryBinding)
                        SettingView(setting: $playgroundController.settings.apmsEnabled)
                        if playgroundController.settings.apmsEnabled == .off {
                            TextField("Supported Payment Methods (comma separated)", text: supportedPaymentMethodsBinding)
                                .autocapitalization(.none)
                        }
                    }
                    Group {
                        if playgroundController.settings.customerKeyType == .customerSession {
                            VStack {
                                HStack {
                                    Text("Customer Session Settings")
                                        .font(.subheadline)
                                        .bold()
                                    Spacer()
                                }
                                SettingPickerView(setting: paymentMethodSaveBinding)
                                if playgroundController.settings.paymentMethodSave == .disabled {
                                    SettingPickerView(setting: $playgroundController.settings.allowRedisplayOverride)
                                }
                                SettingPickerView(setting: $playgroundController.settings.paymentMethodRemove)
                                SettingPickerView(setting: $playgroundController.settings.paymentMethodRemoveLast)
                                SettingPickerView(setting: paymentMethodRedisplayBinding)
                                if playgroundController.settings.paymentMethodRedisplay == .enabled {
                                    SettingPickerView(setting: $playgroundController.settings.paymentMethodAllowRedisplayFilters)
                                }
                                SettingPickerView(setting: $playgroundController.settings.allowsSetAsDefaultPM)
                            }
                        }
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
                        TextField("Payment Method Settings ID", text: paymentMethodSettingsBinding)
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

                    if playgroundController.settings.uiStyle == .embedded {
                        Divider()
                        Group {
                            HStack {
                                Text("Embedded only configuration")
                                    .font(.headline)
                                Spacer()
                            }
                            SettingView(setting: $playgroundController.settings.formSheetAction)
                            SettingView(setting: $playgroundController.settings.embeddedViewDisplaysMandateText)
                        }
                    }

                }.padding()
            }
            Spacer()
            Divider()
            PaymentSheetButtons()
                .environmentObject(playgroundController)
        }.animationUnlessTesting()
    }

    var paymentMethodSaveBinding: Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodSave> {
        Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodSave> {
            return playgroundController.settings.paymentMethodSave
        } set: { newValue in
            if playgroundController.settings.paymentMethodSave != newValue {
                playgroundController.settings.allowRedisplayOverride = .notSet
            }
            playgroundController.settings.paymentMethodSave = newValue
        }
    }
    var customCTABinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customCtaLabel ?? ""
        } set: { newString in
            playgroundController.settings.customCtaLabel = (newString != "") ? newString : nil
        }
    }

    var customEmailBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customEmail ?? ""
        } set: { newString in
            playgroundController.settings.customEmail = (newString != "") ? newString : nil
        }
    }

    var paymentMethodSettingsBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.paymentMethodConfigurationId ?? ""
        } set: { newString in
            playgroundController.settings.paymentMethodConfigurationId = (newString != "") ? newString : nil
        }
    }
    var customerModeBinding: Binding<PaymentSheetTestPlaygroundSettings.CustomerMode> {
        Binding<PaymentSheetTestPlaygroundSettings.CustomerMode> {
            return playgroundController.settings.customerMode
        } set: { newMode in
            PlaygroundController.resetCustomer()
            playgroundController.settings.customerMode = newMode
        }
    }
    var paymentMethodRedisplayBinding: Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodRedisplay> {
        Binding<PaymentSheetTestPlaygroundSettings.PaymentMethodRedisplay> {
            return playgroundController.settings.paymentMethodRedisplay
        } set: { newPaymentMethodRedisplay in
            if playgroundController.settings.paymentMethodRedisplay.rawValue != newPaymentMethodRedisplay.rawValue {
                playgroundController.settings.paymentMethodAllowRedisplayFilters = .notSet
            }
            playgroundController.settings.paymentMethodRedisplay = newPaymentMethodRedisplay
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

    var supportedPaymentMethodsBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.supportedPaymentMethods ?? ""
        } set: { newString in
            playgroundController.settings.supportedPaymentMethods = newString
        }
    }

    var uiStyleBinding: Binding<PaymentSheetTestPlaygroundSettings.UIStyle> {
        Binding<PaymentSheetTestPlaygroundSettings.UIStyle> {
            return playgroundController.settings.uiStyle
        } set: { newUIStyle in
            // If we switch to embedded set confirmation type to deferred CSC if in intent first confirmation type
            if newUIStyle == .embedded && playgroundController.settings.integrationType == .normal {
                playgroundController.settings.integrationType = .deferred_csc
            }

            playgroundController.settings.uiStyle = newUIStyle
        }
    }

    var integrationTypeBinding: Binding<PaymentSheetTestPlaygroundSettings.IntegrationType> {
        Binding<PaymentSheetTestPlaygroundSettings.IntegrationType> {
            return playgroundController.settings.integrationType
        } set: { newIntegrationType in
            // If switching to CSC and embedded is selected, reset to PaymentSheet
            if newIntegrationType == .normal && playgroundController.settings.uiStyle == .embedded {
                playgroundController.settings.uiStyle = .paymentSheet
            }
            playgroundController.settings.integrationType = newIntegrationType
        }
    }
}

extension View {
    func animationUnlessTesting() -> some View {
        if ProcessInfo.processInfo.environment["UITesting"] != nil {
            return AnyView(animation(.bouncy).transition(.opacity))
        }
        return AnyView(self)
    }
}

struct EmbeddedSettingsView: View {
    @EnvironmentObject var playgroundController: PlaygroundController

    var body: some View {
        SettingView(setting: $playgroundController.settings.mode)
    }
}

@available(iOS 14.0, *)
struct PaymentSheetButtons: View {
    @EnvironmentObject var playgroundController: PlaygroundController
    @State private var psIsPresented: Bool = false
    @State private var embeddedIsPresented: Bool = false
    @State private var psFCOptionsIsPresented: Bool = false
    @State private var psFCIsConfirming: Bool = false

    func reloadPlaygroundController() {
        playgroundController.load(reinitializeControllers: true)
    }

    // This exists so that the embedded playground vc (EPVC) can call the `EmbeddedPaymentElement.update` API
    // We build the settings view here, rather than in EPVC, so that it can easily update the PI/SI like all other settings and ensure the PI/SI is up to date when it's eventually used at confirm-time
    @ViewBuilder
    var embeddedSettingsView: some View {
        EmbeddedSettingsView()
    }

    var titleAndReloadView: some View {
        HStack {
            Text(playgroundController.settings.uiStyle.rawValue)
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
    }

    var body: some View {
        VStack {
            switch playgroundController.settings.uiStyle {
            case .paymentSheet:
                VStack {
                    titleAndReloadView
                    if let ps = playgroundController.paymentSheet,
                       playgroundController.lastPaymentResult == nil || playgroundController.lastPaymentResult?.shouldAllowPresentingPaymentSheet() ?? false {
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
            case .flowController:
                VStack {
                    titleAndReloadView
                    HStack {
                        if let psfc = playgroundController.paymentSheetFlowController,
                           playgroundController.lastPaymentResult == nil || playgroundController.lastPaymentResult?.shouldAllowPresentingPaymentSheet() ?? false {
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
            case .embedded:
                VStack {
                    titleAndReloadView
                    if playgroundController.embeddedPlaygroundViewController != nil,
                       playgroundController.lastPaymentResult == nil || playgroundController.lastPaymentResult?.shouldAllowPresentingPaymentSheet() ?? false {
                        HStack {
                            Button {
                                embeddedIsPresented = true
                                playgroundController.presentEmbedded(settingsView: {
                                    embeddedSettingsView.environmentObject(playgroundController)
                                })
                            } label: {
                                Text("Present embedded payment element")
                            }
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
                        Text("Embedded payment element is nil")
                        .foregroundColor(.gray)
                        .padding()
                    }
                    if let result = playgroundController.lastPaymentResult {
                        ExamplePaymentStatusView(result: result)
                    }
                }
            }
        }
    }
}

extension PaymentSheetResult {
    func shouldAllowPresentingPaymentSheet() -> Bool {
        switch self {
        case .canceled, .failed:
            return true
        case .completed:
            return false
        }
    }
}

/// A zero-sized view whose only purpose is to let XCUITests access the analytics sent by the SDK.
struct AnalyticsLogForTesting: View {
    @Binding var analyticsLog: [[String: Any]]
    var analyticsLogString: String {
        return try! JSONSerialization.data(withJSONObject: analyticsLog).base64EncodedString()
    }
    var body: some View {
        Text(analyticsLogString)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibility(identifier: "_testAnalyticsLog")
            .accessibility(label: Text(analyticsLogString))
            .accessibility(hidden: false)
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
        VStack {
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
            }
            if let email = billingDetails.email {
                Text(email)
            }
            if let phone = billingDetails.phoneNumberForDisplay {
                Text(phone)
            }
            if let line1 = billingDetails.address.line1 {
                Text(line1)
            }
            if let line2 = billingDetails.address.line2 {
                Text(line2)
            }
            if let city = billingDetails.address.city {
                Text(city)
            }
            if let state = billingDetails.address.state {
                Text(state)
            }
            if let postalCode = billingDetails.address.postalCode {
                Text(postalCode)
            }
            if let country = billingDetails.address.country {
                Text(country)
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
    var disabledSettings: [S] = []

    var body: some View {
        HStack {
            Text(S.enumName).font(.subheadline)
            Spacer()
            Picker(S.enumName, selection: setting) {
                ForEach(S.allCases.filter({ !disabledSettings.contains($0) }), id: \.self) { t in
                    Text(t.displayName)
                }
            }.layoutPriority(0.8)
        }
    }
}

@available(iOS 15.0, *)
struct PaymentSheetTestPlayground_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetTestPlayground(settings: .defaultValues())
    }
}
