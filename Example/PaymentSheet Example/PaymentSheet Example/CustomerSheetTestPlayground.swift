//
//  CustomerSheetTestPlayground.swift
//  PaymentSheet Example
//
//  ⚠️🏗 This is a playground for internal Stripe engineers to help us test things, and isn't
//  an example of what you should do in a real app!
//  Note: Do not import Stripe using `@_spi(STP)` or @_spi(PrivateBetaCustomerSheet) in production.
//  This exposes internal functionality which may cause unexpected behavior if used directly.

import Contacts
import Foundation
import PassKit
@_spi(PrivateBetaCustomerSheet) import StripePaymentSheet
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
                        TextField("CustomerId", text: customerIdBinding)
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
                        SettingView(setting: $playgroundController.settings.paymentMethodMode)
                        SettingView(setting: $playgroundController.settings.applePay)
                        SettingView(setting: $playgroundController.settings.defaultBillingAddress)
                        SettingView(setting: $playgroundController.settings.autoreload)
                        TextField("headerTextForSelectionScreen", text: headerTextForSelectionScreenBinding)
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
        }.padding()
            .foregroundColor(.black)
            .cornerRadius(6)
    }
}
