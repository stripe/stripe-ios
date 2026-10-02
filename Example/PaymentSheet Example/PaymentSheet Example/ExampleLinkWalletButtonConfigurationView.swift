//
//  ExampleLinkWalletButtonConfigurationView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

@_spi(LinkControllerPreview) import StripePaymentSheet

struct LinkWalletButtonDemoConfiguration {
    var email: String = "foo@bar.com"
    var phone: String = ""
    var supportedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    var useCustomAppearance: Bool = false
    var uiFramework: UIFramework = .swiftUI
    var showsPaymentMethodPreviewOnButton: Bool = true

    enum UIFramework: String, CaseIterable {
        case swiftUI = "SwiftUI"
        case uiKit = "UIKit"
    }

    var appearance: LinkAppearance? {
        var linkControllerConfiguration = LinkControllerDemoConfiguration()
        linkControllerConfiguration.useCustomAppearance = useCustomAppearance
        return linkControllerConfiguration.appearance
    }
}

@available(iOS 16.0, *)
struct ExampleLinkWalletButtonConfigurationView: View {
    @State private var configuration = LinkWalletButtonDemoConfiguration()
    @State private var isShowingCheckout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("LinkWalletButton Demo")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                DemoSection(title: "User Information") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                            TextField("Enter email address", text: $configuration.email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (optional)")
                                .font(.subheadline)
                            TextField("Enter phone number (E.164 format)", text: $configuration.phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                }

                DemoSection(title: "Supported Payment Method Types") {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(LinkPaymentMethodType.allCases, id: \.self) { paymentMethodType in
                            Button {
                                if configuration.supportedPaymentMethodTypes.contains(paymentMethodType) {
                                    configuration.supportedPaymentMethodTypes.remove(paymentMethodType)
                                } else {
                                    configuration.supportedPaymentMethodTypes.insert(paymentMethodType)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: configuration.supportedPaymentMethodTypes.contains(paymentMethodType) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(configuration.supportedPaymentMethodTypes.contains(paymentMethodType) ? .blue : .gray)
                                    Text(paymentMethodTypeTitle(paymentMethodType))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                DemoSection(title: "Button Integration") {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Button Integration", selection: $configuration.uiFramework) {
                            ForEach(LinkWalletButtonDemoConfiguration.UIFramework.allCases, id: \.self) { framework in
                                Text(framework.rawValue).tag(framework)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch configuration.uiFramework {
                        case .swiftUI:
                            Text("Embeds the button with LinkWalletButtonView. The presenting view controller is found from the button's window.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        case .uiKit:
                            Text("Embeds LinkWalletButton in a UIViewController with Auto Layout and sets its presentingViewController.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Toggle("Show PM preview on button", isOn: $configuration.showsPaymentMethodPreviewOnButton)
                        Text("When off, the button shows the customer's email instead of their payment method.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                DemoSection(title: "Appearance") {
                    Toggle("Custom Appearance", isOn: $configuration.useCustomAppearance)
                    if configuration.useCustomAppearance {
                        Text("Purple primary color, always dark mode, slightly less rounded button in the Link flow.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button("Launch demo") {
                    isShowingCheckout = true
                }
                .buttonStyle(PreviewPrimaryButtonStyle())
                .disabled(configuration.email.isEmpty)
                .opacity(configuration.email.isEmpty ? 0.4 : 1)
            }
            .padding()
        }
        .navigationTitle("Configuration")
        .fullScreenCover(isPresented: $isShowingCheckout) {
            NavigationStack {
                ExampleLinkWalletButtonCheckoutView(configuration: configuration)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") {
                                isShowingCheckout = false
                            }
                        }
                    }
            }
        }
    }

    private func paymentMethodTypeTitle(_ paymentMethodType: LinkPaymentMethodType) -> String {
        switch paymentMethodType {
        case .card:
            return "Card"
        case .bankAccount:
            return "Bank Account"
        @unknown default:
            fatalError()
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    NavigationStack {
        ExampleLinkWalletButtonConfigurationView()
    }
}
