//
//  ExampleLinkControllerPreviewView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

@_spi(LinkControllerPreview) import StripePaymentSheet
import StripePayments

@available(iOS 16.0, *)
struct ExampleLinkControllerPreviewView: View {
    @State private var linkController: LinkController?
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var statusTint: Color = .secondary
    @State private var selectedPaymentMethodTypes: Set<LinkPaymentMethodType> = Set(LinkPaymentMethodType.allCases)
    @State private var customerId: String?
    @State private var savedPaymentMethods: [LinkControllerDemoBackendClient.PaymentMethodInfo] = []
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

                VStack(spacing: 16) {
                    Button("Fetch Customer") {
                        Task { @MainActor in
                            do {
                                try await fetchCustomer()
                            } catch {
                                errorMessage = "Failed to fetch customer: \(error.localizedDescription)"
                            }
                        }
                    }
                    .buttonStyle(PreviewPrimaryButtonStyle())
                    .disabled(isLoading || email.isEmpty)

                    if !savedPaymentMethods.isEmpty {
                        DemoSection(title: "Saved Payment Methods") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(savedPaymentMethods) { pm in
                                    HStack(spacing: 12) {
                                        Text(pm.displayLabel)
                                            .font(.subheadline)
                                        Spacer()
                                        Button("Pay $10.99") {
                                            Task { @MainActor in
                                                await chargePaymentMethod(pm)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .fixedSize()
                                        .disabled(isLoading)

                                        Button("−") {
                                            Task { @MainActor in
                                                await removePaymentMethod(pm)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                        .disabled(isLoading)
                                    }
                                }
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

                    Button("Present Link") {
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
                    MessageBanner(text: statusMessage, tint: statusTint)
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
        linkController = nil
        isLoading = true
        errorMessage = nil
        statusMessage = "Initializing LinkController..."

        do {
            let config = try await LinkControllerDemoBackendClient.fetchConfig()
            STPAPIClient.shared.publishableKey = config.publishableKey

            linkController = try await LinkController.create(
                configuration: .init(supportedPaymentMethodTypes: supportedPaymentMethodTypes, merchantDisplayName: "Example, Inc.")
            )
            isLoading = false
            statusTint = .secondary
            statusMessage = "LinkController initialized successfully"
        } catch {
            isLoading = false
            statusMessage = nil
            errorMessage = "Failed to initialize LinkController: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func fetchCustomer() async throws {
        isLoading = true
        errorMessage = nil
        statusMessage = "Fetching customer..."
        do {
            customerId = try await LinkControllerDemoBackendClient.fetchOrCreateCustomer(email: email)
            try await refreshSavedPaymentMethods()
            isLoading = false
            statusMessage = "Customer fetched (ID: \(customerId!))"
        } catch {
            isLoading = false
            statusMessage = nil
            customerId = nil
            throw error
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

        if customerId == nil {
            guard !email.isEmpty else {
                errorMessage = "Enter an email first"
                return
            }
            do {
                try await fetchCustomer()
            } catch {
                errorMessage = "Failed to fetch customer: \(error.localizedDescription)"
                return
            }
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
                statusMessage = "Saving payment method..."
                do {
                    try await LinkControllerDemoBackendClient.attachPaymentMethod(
                        paymentMethod.stripeId,
                        toCustomer: customerId!
                    )
                    try await refreshSavedPaymentMethods()
                    statusMessage = "Payment method saved!"
                } catch {
                    statusMessage = "Payment method created (ID: \(paymentMethod.stripeId)) but failed to save: \(error.localizedDescription)"
                }
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
    private func refreshSavedPaymentMethods() async throws {
        guard let customerId else { return }
        savedPaymentMethods = try await LinkControllerDemoBackendClient.listPaymentMethods(for: customerId)
    }

    @MainActor
    private func chargePaymentMethod(_ pm: LinkControllerDemoBackendClient.PaymentMethodInfo) async {
        guard let customerId else { return }
        isLoading = true
        errorMessage = nil
        do {
            let response = try await LinkControllerDemoBackendClient.charge(
                paymentMethodId: pm.id,
                customerId: customerId
            )

            if response.code == "authentication_required", let secret = response.clientSecret {
                guard let vc = findViewController() else {
                    isLoading = false
                    errorMessage = "Could not find view controller for 3DS authentication"
                    return
                }
                let authContext = STPAuthenticationContextWrapper(vc)
                let authStatus: STPPaymentHandlerActionStatus = await withCheckedContinuation { continuation in
                    STPPaymentHandler.shared().handleNextAction(
                        forPayment: secret,
                        with: authContext,
                        returnURL: nil
                    ) { status, _, _ in
                        continuation.resume(returning: status)
                    }
                }
                isLoading = false
                switch authStatus {
                case .succeeded:
                    statusMessage = "Payment authenticated and complete"
                case .canceled:
                    statusMessage = "Authentication canceled"
                case .failed:
                    errorMessage = "Authentication failed"
                @unknown default:
                    break
                }
            } else if response.status == "processing" {
                isLoading = false
                statusTint = .yellow
                statusMessage = "Payment processing (ID: \(response.paymentIntentId))..."
                await pollPaymentIntentStatus(piId: response.paymentIntentId)
            } else {
                isLoading = false
                statusMessage = "Payment \(response.status) (ID: \(response.paymentIntentId))"
            }
        } catch {
            isLoading = false
            errorMessage = "Payment failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func pollPaymentIntentStatus(piId: String) async {
        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let response = try? await LinkControllerDemoBackendClient.fetchPaymentIntentStatus(piId: piId) else {
                continue
            }
            if response.status != "processing" {
                statusTint = .green
                statusMessage = "Payment \(response.status) (ID: \(piId))"
                return
            }
        }
        statusMessage = "Payment still processing (ID: \(piId))"
    }

    @MainActor
    private func removePaymentMethod(_ pm: LinkControllerDemoBackendClient.PaymentMethodInfo) async {
        isLoading = true
        errorMessage = nil
        do {
            try await LinkControllerDemoBackendClient.detachPaymentMethod(pm.id)
            try await refreshSavedPaymentMethods()
            isLoading = false
            statusMessage = "Payment method removed"
        } catch {
            isLoading = false
            errorMessage = "Failed to remove payment method: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func resetLinkController() async {
        linkController = nil
        errorMessage = nil
        statusMessage = nil
        statusTint = .secondary
        email = ""
        phone = ""
        customerId = nil
        savedPaymentMethods = []
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

private class STPAuthenticationContextWrapper: NSObject, STPAuthenticationContext {
    private let viewController: UIViewController
    init(_ viewController: UIViewController) { self.viewController = viewController }
    func authenticationPresentingViewController() -> UIViewController { viewController }
}

@available(iOS 16.0, *)
#Preview {
    ExampleLinkControllerPreviewView()
}
