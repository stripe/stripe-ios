//
//  ExampleLinkControllerPreviewView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

@_spi(LinkControllerPreview) import StripePaymentSheet

@available(iOS 16.0, *)
struct ExampleLinkControllerPreviewView: View {
    private static let publishableKey = "pk_test_51K9W3OHMaDsveWq0oLP0ZjldetyfHIqyJcz27k2BpMGHxu9v9Cei2tofzoHncPyk3A49jMkFEgTOBQyAMTUffRLa00xzzARtZO"

    @State private var linkController: LinkController?
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var selectedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    @FocusState private var isEmailFieldFocused: Bool

    private var supportedPaymentMethodTypes: [LinkPaymentMethodType] {
        LinkPaymentMethodType.allCases.filter(selectedPaymentMethodTypes.contains)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LinkControllerPreview Demo")
                        .font(.system(size: 34, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                DemoSection(title: "User Information") {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                            TextField("Enter email address", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($isEmailFieldFocused)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (optional)")
                                .font(.subheadline)
                            TextField("Enter phone number (E.164 format)", text: $phone)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                }

                DemoSection(title: "Supported Payment Method Types") {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(LinkPaymentMethodType.allCases, id: \.self) { paymentMethodType in
                            Button {
                                Task { @MainActor in
                                    await togglePaymentMethodType(paymentMethodType)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: selectedPaymentMethodTypes.contains(paymentMethodType) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(selectedPaymentMethodTypes.contains(paymentMethodType) ? .blue : .gray)
                                    Text(paymentMethodTypeTitle(paymentMethodType))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isLoading)
                        }
                    }
                }

                VStack(spacing: 16) {
                    Button("Present") {
                        Task { @MainActor in
                            await presentLinkFlow()
                        }
                    }
                    .buttonStyle(PreviewPrimaryButtonStyle())
                    .disabled(isLoading || linkController == nil)

                    Button("Reset LinkController") {
                        Task { @MainActor in
                            await resetLinkController()
                        }
                    }
                    .buttonStyle(PreviewTextButtonStyle())
                    .disabled(isLoading)
                }

                if let errorMessage {
                    MessageBanner(text: errorMessage, tint: .red)
                }

                if let statusMessage {
                    MessageBanner(text: statusMessage, tint: .green)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Payment Method Preview")
                        .font(.headline)
                    if let linkController {
                        LinkControllerPreviewPaymentMethodView(linkController: linkController)
                    } else {
                        StatusCard(
                            text: "No payment method preview available",
                            isPlaceholder: true
                        )
                    }
                }
            }
            .padding()
        }
        .task {
            guard linkController == nil, !isLoading else {
                return
            }
            await initializeLinkController()
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView("Loading...")
                        .padding(20)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    @MainActor
    private func initializeLinkController() async {
        STPAPIClient.shared.publishableKey = Self.publishableKey

        linkController = nil
        isLoading = true
        errorMessage = nil
        statusMessage = "Initializing LinkController..."

        do {
            linkController = try await LinkController.create(
                configuration: .init(supportedPaymentMethodTypes: supportedPaymentMethodTypes)
            )
            isLoading = false
            statusMessage = "LinkController initialized successfully"
        } catch {
            isLoading = false
            statusMessage = nil
            errorMessage = "Failed to initialize LinkController: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func presentLinkFlow() async {
        guard let linkController else {
            errorMessage = "LinkController not initialized"
            return
        }

        guard let rootViewController = findViewController() else {
            errorMessage = "Could not find root view controller"
            return
        }

        isEmailFieldFocused = false
        isLoading = true
        errorMessage = nil
        statusMessage = "Presenting Link flow..."

        do {
            let result = try await linkController.present(
                email: email,
                phoneNumber: phone.isEmpty ? nil : phone,
                from: rootViewController
            )

            isLoading = false

            switch result {
            case .completed(let paymentMethod):
                statusMessage = "Payment method created (ID: \(paymentMethod.stripeId))"
            case .canceled:
                statusMessage = "Present flow canceled"
            }
        } catch {
            isLoading = false
            statusMessage = nil
            errorMessage = "Present flow failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func resetLinkController() async {
        linkController = nil
        errorMessage = nil
        statusMessage = nil
        email = ""
        phone = ""
        selectedPaymentMethodTypes = Set(LinkPaymentMethodType.allCases)

        await initializeLinkController()
    }

    @MainActor
    private func togglePaymentMethodType(_ paymentMethodType: LinkPaymentMethodType) async {
        if selectedPaymentMethodTypes.contains(paymentMethodType) {
            selectedPaymentMethodTypes.remove(paymentMethodType)
        } else {
            selectedPaymentMethodTypes.insert(paymentMethodType)
        }

        await initializeLinkController()
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

    private func findViewController() -> UIViewController? {
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
}

@available(iOS 16.0, *)
private struct LinkControllerPreviewPaymentMethodView: View {
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

private struct DemoSection<Content: View>: View {
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
private struct PreviewInfoRow: View {
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
private struct StatusCard: View {
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
private struct MessageBanner: View {
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
private struct PreviewPrimaryButtonStyle: ButtonStyle {
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
private struct PreviewTextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .foregroundColor(.primary)
            .padding(.vertical, 8)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

@available(iOS 16.0, *)
#Preview {
    ExampleLinkControllerPreviewView()
}
