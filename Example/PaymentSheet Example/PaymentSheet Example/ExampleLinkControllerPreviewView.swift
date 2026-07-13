//
//  ExampleLinkControllerPreviewView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

import StripePayments
@_spi(LinkControllerPreview) import StripePaymentSheet

@available(iOS 16.0, *)
struct ExampleLinkControllerPreviewView: View {
    @State private var configuration = LinkControllerDemoConfiguration()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Link Standalone Demo")
                            .font(.system(size: 34, weight: .bold))
                    }
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

                    DemoSection(title: "Intent Mode") {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Intent Mode", selection: $configuration.intentMode) {
                                ForEach(LinkControllerDemoConfiguration.IntentMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            switch configuration.intentMode {
                            case .sdkManaged:
                                Text("LinkController manages the session; the app attaches the payment method manually after `present` returns.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            case .serverSetupIntent:
                                Text("A SetupIntent is created server-side before presenting. The SDK confirms and attaches automatically.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    NavigationLink {
                        LinkControllerDemoView(configuration: configuration)
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(configuration.email.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(configuration.email.isEmpty)
                }
                .padding()
        }
        .navigationTitle("Configuration")
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

func findViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow)

    var topController = keyWindow?.rootViewController
    while let presentedViewController = topController?.presentedViewController {
        topController = presentedViewController
    }
    return topController
}

@available(iOS 16.0, *)
struct LinkControllerPreviewPaymentMethodView: View {
    @ObservedObject var linkController: LinkController

    var body: some View {
        if let paymentMethodPreview = linkController.paymentMethodPreview {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Icon:")
                        .fontWeight(.medium)
                    Spacer()
                    Image(uiImage: paymentMethodPreview.icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                PreviewInfoRow(label: "Label", value: paymentMethodPreview.label)
                PreviewInfoRow(label: "Sublabel", value: paymentMethodPreview.sublabel ?? "N/A")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            StatusCard(
                text: "No payment method preview available",
                isPlaceholder: true
            )
        }
    }
}

struct DemoSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

@available(iOS 16.0, *)
struct PreviewInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(label):")
                .fontWeight(.medium)
            Spacer(minLength: 12)
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .truncationMode(.middle)
        }
    }
}

@available(iOS 16.0, *)
struct StatusCard: View {
    let text: String
    let isPlaceholder: Bool

    var body: some View {
        Group {
            if isPlaceholder {
                Text(text)
                    .italic()
            } else {
                Text(text)
            }
        }
            .foregroundColor(isPlaceholder ? .secondary : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 16.0, *)
struct MessageBanner: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(tint.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

@available(iOS 16.0, *)
struct PreviewPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

@available(iOS 16.0, *)
struct PreviewTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

class STPAuthenticationContextWrapper: NSObject, STPAuthenticationContext {
    private let viewController: UIViewController
    init(_ viewController: UIViewController) { self.viewController = viewController }
    func authenticationPresentingViewController() -> UIViewController { viewController }
}

@available(iOS 16.0, *)
#Preview {
    ExampleLinkControllerPreviewView()
}
