//
//  LinkPayControllerTestPlayground.swift
//  PaymentSheet Example
//
//  Created by Vardges Avetisyan on 6/26/23.
//

@_spi(LinkOnly) import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct LinkPayControllerTestPlayground: View {
    @StateObject var playgroundController: LinkPayPlaygroundController

    init(settings: LinkPayPlaygroundControllerSettings) {
        _playgroundController = StateObject(wrappedValue: LinkPayPlaygroundController(settings: settings))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Group {
                        SettingView(setting: $playgroundController.settings.mode)
                        SettingPickerView(setting: $playgroundController.settings.integrationType)
                    }
                }.padding()
            }
            Spacer()
            Divider()
            LinkPayControllerTestPlaygroundButtons()
                .environmentObject(playgroundController)
        }
    }
}

@available(iOS 14.0, *)
struct LinkPayControllerTestPlaygroundButtons: View {
    @EnvironmentObject var playgroundController: LinkPayPlaygroundController
    @State var psIsPresented: Bool = false
    @State var psFCOptionsIsPresented: Bool = false
    @State var psFCIsConfirming: Bool = false

    func reloadPlaygroundController() {
        playgroundController.load()
    }

    var body: some View {
        VStack {
                VStack {
                    HStack {
                        Text("LinkPayController")
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
                        if let lpc = playgroundController.linkPayController {
                            Button {
                                psFCOptionsIsPresented = true
                            } label: {
                                Text("Add Payment")
                            }
                            .padding()

                            Button {
                                psFCIsConfirming = true
                            } label: {
                                Text("Confirm")
                            }
                            .disabled(playgroundController.linkPayController?.paymentMethodId == nil)
                            .linkPaymentConfirmationSheet(isConfirming: $psFCIsConfirming, linkPaymentController: lpc, onCompletion: playgroundController.onPSFCCompletion)
                            .linkPaymentOptionsSheet(isPresented: $psFCOptionsIsPresented, linkPaymentController: lpc, onSheetDismissed: playgroundController.onOptionsCompletion)
                            .padding()
                        } else {
                            Text("LinkPayController is nil")
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


@available(iOS 15.0, *)
struct LinkPayControllerTestPlayground_Previews: PreviewProvider {
    static var previews: some View {
        LinkPayControllerTestPlayground(settings: .defaultValues())
    }
}
