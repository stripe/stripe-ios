//
//  CustomerSheetTestPlayground.swift
//  PaymentSheet Example
//
//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.

import Contacts
import Foundation
import PassKit
import StripePaymentSheet
import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct CustomerSheetTestPlayground: View {
    @StateObject var playgroundController: CustomerSheetTestPlaygroundController

    init(settings: CustomerSheetTestPlaygroundSettings) {
        _playgroundController = StateObject(wrappedValue: CustomerSheetTestPlaygroundController(settings: settings))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Group {
                        HStack {
                            Text("Backend").font(.headline)
                            Spacer()
                            Button {
                                playgroundController.didTapResetConfig()
                            } label: {
                                Text("Reset")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                        }
                        SettingView(setting: $playgroundController.settings.customerMode)
                        SettingView(setting: customerKeyTypeBinding)
                        TextField("CustomerId", text: customerIdBinding)
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
                                SettingPickerView(setting: $playgroundController.settings.paymentMethodRemove)
                                SettingPickerView(setting: $playgroundController.settings.paymentMethodRemoveLast)
                                SettingPickerView(setting: $playgroundController.settings.paymentMethodAllowRedisplayFilters)
                                SettingPickerView(setting: $playgroundController.settings.allowsSetAsDefaultPM)
                            }
                        }
                    }
                    Group {
                        HStack {
                            Text("Client Configuration").font(.headline)
                            Spacer()
                            Button {
                                playgroundController.appearanceButtonTapped()
                            } label: {
                                Text("Appearance").font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                        }
                        SettingPickerView(setting: merchantCountryBinding)
                        SettingView(setting: paymentMethodModeBinding)
                        SettingView(setting: $playgroundController.settings.applePay)
                        SettingView(setting: $playgroundController.settings.defaultBillingAddress)
                        SettingView(setting: $playgroundController.settings.preferredNetworksEnabled)
                        SettingView(setting: $playgroundController.settings.cardBrandAcceptance)
                        SettingView(setting: $playgroundController.settings.autoreload)
                        TextField("headerTextForSelectionScreen", text: headerTextForSelectionScreenBinding)
                        SettingView(setting: $playgroundController.settings.allowsRemovalOfLastSavedPaymentMethod)
                        HStack {
                            Text("Macros").font(.headline)
                            Spacer()
                            Button {
                                playgroundController.didTapSetToUnsupported()
                            } label: {
                                Text("SetPMLink")
                                    .font(.callout.smallCaps())
                            }.buttonStyle(.bordered)
                        }
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
                }
            }
            Spacer()
            Divider()
            CustomerSheetButtons()
                .environmentObject(playgroundController)
        }
    }
    var customerKeyTypeBinding: Binding<CustomerSheetTestPlaygroundSettings.CustomerKeyType> {
        Binding<CustomerSheetTestPlaygroundSettings.CustomerKeyType> {
            return playgroundController.settings.customerKeyType
        } set: { newKeyType in
            // If switching to customerSession preselect setupIntent
            if playgroundController.settings.customerKeyType.rawValue != newKeyType.rawValue && newKeyType == .customerSession {
                playgroundController.settings.paymentMethodMode = .setupIntent
            }
            playgroundController.settings.customerKeyType = newKeyType
        }
    }
    var paymentMethodModeBinding: Binding<CustomerSheetTestPlaygroundSettings.PaymentMethodMode> {
        Binding<CustomerSheetTestPlaygroundSettings.PaymentMethodMode> {
            return playgroundController.settings.paymentMethodMode
        } set: { newPaymentMethodMode in
            // If switching to createAndAttach, ensure using legacy customer ephemeralKey
            if playgroundController.settings.paymentMethodMode.rawValue != newPaymentMethodMode.rawValue && newPaymentMethodMode == .createAndAttach {
                playgroundController.settings.customerKeyType = .legacy
            }
            playgroundController.settings.paymentMethodMode = newPaymentMethodMode
        }
    }
    var merchantCountryBinding: Binding<CustomerSheetTestPlaygroundSettings.MerchantCountry> {
        Binding<CustomerSheetTestPlaygroundSettings.MerchantCountry> {
            return playgroundController.settings.merchantCountryCode
        } set: { newCountry in
            // Reset customer id if country changes
            if playgroundController.settings.merchantCountryCode.rawValue != newCountry.rawValue {
                playgroundController.settings.customerMode = .new
            }
            playgroundController.settings.merchantCountryCode = newCountry
        }
    }

    var customerIdBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.customerId ?? ""
        } set: { newString in
            playgroundController.settings.customerId = (newString != "") ? newString : nil
        }
    }
    var headerTextForSelectionScreenBinding: Binding<String> {
        Binding<String> {
            return playgroundController.settings.headerTextForSelectionScreen ?? ""
        } set: { newString in
            playgroundController.settings.headerTextForSelectionScreen = (newString != "") ? newString : nil
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

@available(iOS 14.0, *)
struct CustomerSheetButtons: View {
    @EnvironmentObject var playgroundController: CustomerSheetTestPlaygroundController
    @State var csIsPresented: Bool = false

    func reloadPlaygroundController() {
        playgroundController.load()
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("CustomerSheet")
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
                    if playgroundController.customerSheet != nil {
                        HStack{
                            Text("Payment method").font(.subheadline)
                            Spacer()
                            Button {
                                // A bit of a hack here, but we need to work on dismissing the keyboard better
                                hideKeyboard()
                                playgroundController.presentCustomerSheet()
                                csIsPresented = true
                            } label: {
                                CustomerSheetPaymentOptionView(paymentOptionDisplayData: playgroundController.paymentOptionSelection)
                            }
                            .disabled(playgroundController.customerSheet == nil)
                        }
                        .padding()
                    } else {
                        Text("CustomerSheet is nil")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
    }
}

struct CustomerSheetPaymentOptionView: View {
    let paymentOptionDisplayData: CustomerSheet.PaymentOptionSelection?

    var body: some View {
        HStack {
            Image(uiImage: paymentOptionDisplayData?.displayData().image ?? UIImage())
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 30, maxHeight: 30, alignment: .leading)
                .foregroundColor(.black)
            Text(paymentOptionDisplayData?.displayData().label ?? "None")
                .accessibility(identifier: "Payment method")
                .foregroundColor(.primary)
        }.padding()
            .foregroundColor(.black)
            .cornerRadius(6)
    }
}
