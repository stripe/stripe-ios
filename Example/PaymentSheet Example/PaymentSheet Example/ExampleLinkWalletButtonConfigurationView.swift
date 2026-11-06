//
//  ExampleLinkWalletButtonConfigurationView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) import StripePaymentSheet

struct LinkWalletButtonDemoConfiguration {
    var email: String = "foo@bar.com"
    var phone: String = ""
    var supportedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    var useCustomAppearance: Bool = false
    var uiFramework: UIFramework = .swiftUI
    var showsPaymentMethodPreviewOnButton: Bool = true
    var linkBrand: LinkBrandOverride = .automatic
    var integration: Integration = .collectPaymentMethod
    var confirmOnServer: Bool = false

    let amount = 1099
    let currency = "usd"

    enum Integration: String, CaseIterable {
        case collectPaymentMethod = "Collect payment method"
        case payInLink = "Pay in Link"
    }

    enum UIFramework: String, CaseIterable {
        case swiftUI = "SwiftUI"
        case uiKit = "UIKit"
    }

    enum LinkBrandOverride: String, CaseIterable {
        case automatic = "Automatic"
        case link = "Link"
        case onelink = "Onelink"

        /// The brand to force, or `nil` to let Stripe choose.
        var brand: LinkBrand? {
            switch self {
            case .automatic: nil
            case .link: .link
            case .onelink: .onelink
            }
        }
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
                            Text("Email (optional)")
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

                DemoSection(title: "Intent Integration") {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Intent Integration", selection: $configuration.integration) {
                            ForEach(LinkWalletButtonDemoConfiguration.Integration.allCases, id: \.self) { integration in
                                Text(integration.rawValue).tag(integration)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch configuration.integration {
                        case .collectPaymentMethod:
                            Text("The LinkController is created without an IntentConfiguration. The button returns the selected payment method, and the merchant places the order.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        case .payInLink:
                            Text("The LinkController is created with a PaymentIntent IntentConfiguration ($10.99 USD). The Link wallet shows a Pay button; the confirm handler creates the payment intent, and Link confirms it.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Toggle("Confirm on server", isOn: $configuration.confirmOnServer)
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

                DemoSection(title: "Link Brand") {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Link Brand", selection: $configuration.linkBrand) {
                            ForEach(LinkWalletButtonDemoConfiguration.LinkBrandOverride.allCases, id: \.self) { brand in
                                Text(brand.rawValue).tag(brand)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Automatic uses the brand chosen by Stripe. Link and Onelink override it for the button and the Link flow.")
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
