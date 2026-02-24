//
//  PaymentSheetTestPlayground.swift
//  PaymentSheet Example
//
//  Created by David Estes on 5/31/23.
//

import StripePaymentSheet
import SwiftUI

// MARK: - PaymentSheetTestPlayground
@available(iOS 15.0, *)
struct PaymentSheetTestPlayground: View {
    @StateObject var playgroundController: PlaygroundController
    @StateObject var analyticsLogObserver: AnalyticsLogObserver = .shared
    @State var showingQRSheet = false
    @State private var isViewReady = false
    @State private var searchText: String = ""
    @State private var visibleSettingsCount: Int = 0

    init() {
        _playgroundController = StateObject(wrappedValue: PlaygroundController())
    }

    init(settings: PaymentSheetTestPlaygroundSettings, appearance: PaymentSheet.Appearance) {
        _playgroundController = StateObject(wrappedValue: PlaygroundController(settings: settings, appearance: appearance))
    }

    @ViewBuilder
    func clientSettings(searchText: Binding<String>) -> some View {
        SearchableSettingView(setting: uiStyleBinding, searchText: searchText)
        if playgroundController.settings.uiStyle != .embedded {
            SearchableSettingView(setting: $playgroundController.settings.layout, searchText: searchText)
        }
        SearchableSettingView(setting: $playgroundController.settings.style, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.shippingInfo, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.applePayEnabled, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.applePayButtonType, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.allowsDelayedPMs, searchText: searchText)
        SearchableSettingPickerView(setting: $playgroundController.settings.defaultBillingAddress, searchText: searchText)
        if playgroundController.settings.defaultBillingAddress == .customEmail {
            SearchableView(searchableName: "Default billing address", searchText: searchText) {
                TextField("Default email", text: customEmailBinding)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        SearchableSettingView(setting: $playgroundController.settings.enablePassiveCaptcha, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.enableAttestationOnConfirmation, searchText: searchText)
        Group {
            if playgroundController.settings.merchantCountryCode == .US {
                SearchableSettingView(setting: linkEnabledModeBinding, searchText: searchText)
            }
            SearchableSettingView(setting: $playgroundController.settings.linkPassthroughMode, searchText: searchText)
            SearchableSettingView(setting: $playgroundController.settings.linkDisplay, searchText: searchText)
        }
        SearchableSettingView(setting: $playgroundController.settings.userOverrideCountry, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.externalPaymentMethods, searchText: searchText)
        // The hardcoded CPM id is only available on our US merchant
        if playgroundController.settings.merchantCountryCode == .US {
            SearchableSettingView(setting: $playgroundController.settings.customPaymentMethods, searchText: searchText)
        }
        SearchableSettingView(setting: $playgroundController.settings.preferredNetworksEnabled, searchText: searchText)
        if playgroundController.settings.preferredNetworksEnabled == .on {
            SearchableSettingView(setting: $playgroundController.settings.cbcRedesignEnabled, searchText: searchText)
        }
        SearchableSettingView(setting: $playgroundController.settings.cardBrandAcceptance, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.cardFundingAcceptance, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.allowsRemovalOfLastSavedPaymentMethod, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.requireCVCRecollection, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.autoreload, searchText: searchText)
        SearchableView(searchableName: "Reset attestation", searchText: searchText) {
            AttestationResetButtonView()
        }
        SearchableSettingView(setting: $playgroundController.settings.shakeAmbiguousViews, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.instantDebitsIncentives, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.fcLiteEnabled, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.opensCardScannerAutomatically, searchText: searchText)
        SearchableSettingView(setting: $playgroundController.settings.termsDisplay, searchText: searchText)
    }

    var body: some View {
        if !isViewReady {
            return AnyView(
                VStack {
                    ProgressView()
                    Text("Loading playground...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.async {
                        isViewReady = true
                    }
                }
            )
        }

        return AnyView(VStack {
            ScrollView {
                LazyVStack {
                    // Hide search bar during UI tests to avoid TextField focus interference
                    if ProcessInfo.processInfo.environment["UITesting"] == nil {
                        SettingsSearchBar(text: $searchText)
                            .padding(.bottom, 8)
                    }

                    Group {
                        SearchableSection(
                            title: "Backend",
                            searchText: $searchText,
                            headerButtons: {
                                if ProcessInfo.processInfo.environment["UITesting"] != nil {
                                    AnalyticsLogForTesting(analyticsLog: $analyticsLogObserver.analyticsLog)
                                }
                                Button {
                                    playgroundController.didTapResetConfig()
                                    searchText = ""
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
                        ) {
                                SearchableSettingView(setting: $playgroundController.settings.mode, searchText: $searchText)
                                SearchableSettingPickerView(
                                    setting: integrationTypeBinding,
                                    disabledSettings: playgroundController.settings.uiStyle == .embedded ? [.normal] : [],
                                    searchText: $searchText
                                )
                                // Only show confirmation mode for deferred integration types
                                if playgroundController.settings.integrationType != .normal {
                                    SearchableSettingView(setting: confirmationModeBinding, searchText: $searchText)
                                }
                                SearchableSettingView(setting: customerKeyTypeBinding, searchText: $searchText)
                                SearchableSettingView(setting: customerModeBinding, searchText: $searchText)
                                SearchableView(searchableName: "Amount Currency", searchText: $searchText) {
                                    HStack {
                                        SettingPickerView(setting: $playgroundController.settings.amount, customDisplayName: { amount in
                                            return amount.customDisplayName(currency: playgroundController.settings.currency)
                                        })
                                        SettingPickerView(setting: $playgroundController.settings.currency)
                                    }
                                }
                                SearchableSettingPickerView(setting: merchantCountryBinding, searchText: $searchText)
                                if playgroundController.settings.merchantCountryCode == .custom {
                                    SearchableView(searchableName: "Merchant", searchText: $searchText) {
                                        TextField("sk_(test/live)_...", text: customSecretKeyBinding)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                        TextField("pk_(test/live)_...", text: customPublishableKeyBinding)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                }
                                SearchableSettingView(setting: $playgroundController.settings.apmsEnabled, searchText: $searchText)
                                if playgroundController.settings.apmsEnabled == .off {
                                    SearchableView(searchableName: "Automatic PMs", searchText: $searchText) {
                                        TextField("Supported Payment Methods (comma separated)", text: supportedPaymentMethodsBinding)
                                            .autocapitalization(.none)
                                            .autocorrectionDisabled()
                                    }
                                }
                            }
                        }
                        SearchableView(searchableName: "Payment Method Options", searchText: $searchText) {
                            VStack {
                                HStack {
                                    Text("Payment Method Options")
                                        .font(.subheadline)
                                    Spacer()
                                    Button {
                                        playgroundController.paymentMethodOptionsSetupFutureUsageSettingsTapped()
                                    } label: {
                                        Text("SetupFutureUsage")
                                            .font(.callout.smallCaps())
                                    }.buttonStyle(.bordered)
                                }
                            }
                        }
                        if playgroundController.settings.customerKeyType == .customerSession {
                            SearchableView(searchableName: "Customer Session", searchText: $searchText) {
                                VStack {
                                    HStack {
                                        Text("Customer Session")
                                            .font(.subheadline)
                                        Spacer()
                                        Button {
                                            playgroundController.customerSessionSettingsTapped()
                                        } label: {
                                            Text("CSSettings")
                                                .font(.callout.smallCaps())
                                        }.buttonStyle(.bordered)
                                    }
                                }
                            }
                        }

                        if searchText.isEmpty {
                            Divider()
                        }
                    Group {
                        SearchableSection(
                            title: "Client",
                            searchText: $searchText,
                            headerButtons: {
                                Button {
                                    playgroundController.appearanceButtonTapped()
                                } label: {
                                    Text("Appearance")
                                        .font(.callout.smallCaps())
                                }.buttonStyle(.bordered)
                            }
                        ) {
                                clientSettings(searchText: $searchText)
                                SearchableView(searchableName: "Custom CTA", searchText: $searchText) {
                                    TextField("Custom CTA", text: customCTABinding)
                                }
                                SearchableView(searchableName: "Payment Method Settings ID", searchText: $searchText) {
                                    TextField("Payment Method Settings ID", text: paymentMethodSettingsBinding)
                                        .autocorrectionDisabled()
                                }
                            }
                        }

                        if searchText.isEmpty {
                            Divider()
                        }
                    Group {
                        SearchableSection(
                            title: "Billing Details Collection",
                            searchText: $searchText
                        ) {
                                SearchableSettingView(setting: $playgroundController.settings.attachDefaults, searchText: $searchText)
                                SearchableSettingView(setting: $playgroundController.settings.collectName, searchText: $searchText)
                                SearchableSettingView(setting: $playgroundController.settings.collectEmail, searchText: $searchText)
                                SearchableSettingView(setting: $playgroundController.settings.collectPhone, searchText: $searchText)
                                SearchableSettingView(setting: $playgroundController.settings.collectAddress, searchText: $searchText)
                                SearchableSettingPickerView(setting: $playgroundController.settings.allowedCountries, searchText: $searchText)
                            }
                        }

                        if playgroundController.settings.uiStyle == .embedded {
                            if searchText.isEmpty {
                                Divider()
                            }
                        Group {
                            SearchableSection(
                                title: "Embedded only configuration",
                                searchText: $searchText
                            ) {
                                    SearchableSettingView(setting: $playgroundController.settings.formSheetAction, searchText: $searchText)
                                    SearchableSettingView(setting: $playgroundController.settings.embeddedViewDisplaysMandateText, searchText: $searchText)
                                    SearchableSettingView(setting: $playgroundController.settings.rowSelectionBehavior, searchText: $searchText)
                                }
                            }
                        }

                    if !searchText.isEmpty && visibleSettingsCount == 0 {
                        EmptySearchResultsView(searchText: searchText)
                    }
                }
                .onPreferenceChange(VisibleSettingsCountKey.self) { count in
                    visibleSettingsCount = count
                }
                .padding()
            }
            Spacer()
            Divider()
            PaymentSheetButtons()
        }
        .environmentObject(playgroundController)
        .animationUnlessTesting())
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

    var merchantCountryBinding: Binding<PaymentSheetTestPlaygroundSettings.MerchantCountry> {
        Binding<PaymentSheetTestPlaygroundSettings.MerchantCountry> {
            return playgroundController.settings.merchantCountryCode
        } set: { newCountry in
            // Reset customer id if country changes
            if playgroundController.settings.merchantCountryCode.rawValue != newCountry.rawValue {
                playgroundController.settings.customerMode = .guest
            }
            // Disable CPMs if we switch to non-US merchant
            if newCountry != .US {
                playgroundController.settings.customPaymentMethods = .off
            }
            // Clear custom keys if we switch to non-custom merchant
            if newCountry != .custom {
                playgroundController.settings.customSecretKey = nil
                playgroundController.settings.customPublishableKey = nil
            }
            playgroundController.settings.merchantCountryCode = newCountry
        }
    }

    var customSecretKeyBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customSecretKey ?? ""
        } set: { newString in
            playgroundController.settings.customSecretKey = newString
        }
    }

    var customPublishableKeyBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customPublishableKey ?? ""
        } set: { newString in
            playgroundController.settings.customPublishableKey = newString
        }
    }

    var linkEnabledModeBinding: Binding<PaymentSheetTestPlaygroundSettings.LinkEnabledMode> {
        Binding<PaymentSheetTestPlaygroundSettings.LinkEnabledMode> {
            return playgroundController.settings.linkEnabledMode
        } set: { newMode in
            // Reset customer id if Link enabled mode changes, as we change the underlying account ID
            if playgroundController.settings.linkEnabledMode.rawValue != newMode.rawValue {
                playgroundController.settings.customerMode = .guest
            }
            playgroundController.settings.linkEnabledMode = newMode
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

    var confirmationModeBinding: Binding<PaymentSheetTestPlaygroundSettings.ConfirmationMode> {
        Binding<PaymentSheetTestPlaygroundSettings.ConfirmationMode> {
            return playgroundController.settings.confirmationMode
        } set: { newMode in
            // If switching to confirmation token mode and legacy (ephemeral key) is selected,
            // automatically switch to customer session
            if newMode == .confirmationToken && playgroundController.settings.customerKeyType == .legacy {
                playgroundController.settings.customerKeyType = .customerSession
            }
            playgroundController.settings.confirmationMode = newMode
        }
    }

    var customerKeyTypeBinding: Binding<PaymentSheetTestPlaygroundSettings.CustomerKeyType> {
        Binding<PaymentSheetTestPlaygroundSettings.CustomerKeyType> {
            return playgroundController.settings.customerKeyType
        } set: { newType in
            // If switching to legacy (ephemeral key) and confirmation token is selected,
            // automatically switch to payment method mode
            if newType == .legacy && playgroundController.settings.confirmationMode == .confirmationToken {
                playgroundController.settings.confirmationMode = .paymentMethod
            }
            playgroundController.settings.customerKeyType = newType
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

struct AttestationResetButtonView: View {
    @State private var presentingAlert = false
    @EnvironmentObject var playgroundController: PlaygroundController

    var body: some View {
        if #available(iOS 15.0, *) {
            Button {
                playgroundController.didTapResetAttestation()
                presentingAlert = true
            } label: {
                Text("Reset attestation")
            }.buttonStyle(.bordered)
                .alert("Attestation key has been reset", isPresented: $presentingAlert, actions: {})
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
    var customDisplayLabel: String?
    var customDisplayName: ((S) -> String)?

    var body: some View {
        HStack {
            Text(customDisplayLabel ?? S.enumName).font(.subheadline)
            Spacer()
            Picker(S.enumName, selection: setting) {
                ForEach(S.allCases.filter({ !disabledSettings.contains($0) }), id: \.self) { t in
                    if let customDisplayName {
                        Text(customDisplayName(t))
                    } else {
                        Text(t.displayName)
                    }
                }
            }.layoutPriority(0.8)
        }
    }
}

@available(iOS 15.0, *)
struct PaymentSheetTestPlayground_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetTestPlayground()
    }
}
