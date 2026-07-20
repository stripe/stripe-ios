//
//  LinkControllerDemoView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

import StripePayments
@_spi(LinkControllerPreview) import StripePaymentSheet

@available(iOS 16.0, *)
struct LinkControllerDemoView: View {
    let configuration: LinkControllerDemoConfiguration

    @State private var phase: Phase = .initializing
    @State private var customerId: String?
    @State private var setupIntentClientSecret: String?
    @State private var linkController: LinkController?
    @State private var savedPaymentMethods: [LinkControllerDemoBackendClient.PaymentMethodInfo] = []
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var statusTint: Color = .secondary

    enum Phase {
        case initializing
        case ready
        case presenting
        /// PM selected; waiting for merchant to tap "Confirm & Save" (serverSetupIntent mode only).
        case awaitingConfirmation(STPPaymentMethod)
        case confirming
        case completed(STPPaymentMethod)
        case error(String)
    }

    private var isLoading: Bool {
        switch phase {
        case .initializing, .presenting, .confirming: return true
        default: return false
        }
    }

    private var isReady: Bool {
        switch phase {
        case .ready, .completed, .awaitingConfirmation: return true
        default: return false
        }
    }

    private var controllerStatusLabel: String {
        switch phase {
        case .initializing: return "Initializing..."
        case .ready: return "Ready"
        case .presenting: return "Presenting..."
        case .awaitingConfirmation: return "Payment method selected"
        case .confirming: return "Confirming..."
        case .completed: return "Completed"
        case .error: return "Error"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DemoSection(title: "Setup") {
                    VStack(alignment: .leading, spacing: 12) {
                        PreviewInfoRow(label: "Customer", value: customerId ?? "Creating...")
                        PreviewInfoRow(label: "Intent Mode", value: configuration.intentMode.rawValue)
                        if configuration.intentMode == .serverSetupIntent {
                            PreviewInfoRow(
                                label: "Setup Intent",
                                value: setupIntentClientSecret.map { "..." + $0.suffix(8) } ?? "Created on Present tap"
                            )
                        }
                        PreviewInfoRow(label: "Controller", value: controllerStatusLabel)
                    }
                }

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

                VStack(spacing: 16) {
                    Button("Present Link") {
                        Task { @MainActor in
                            await presentLinkFlow()
                        }
                    }
                    .buttonStyle(PreviewPrimaryButtonStyle())
                    .disabled(!isReady || isLoading)

                    if case .awaitingConfirmation = phase {
                        Button("Confirm & Save") {
                            Task { @MainActor in
                                await confirmFlow()
                            }
                        }
                        .buttonStyle(PreviewPrimaryButtonStyle())
                        .disabled(isLoading)
                    }
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

                if case .completed(let pm) = phase {
                    DemoSection(title: "Completed Payment Method") {
                        VStack(alignment: .leading, spacing: 12) {
                            PreviewInfoRow(label: "PM ID", value: pm.stripeId)
                            PreviewInfoRow(label: "Mode", value: configuration.intentMode.rawValue)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Demo")
        .task {
            await initialize()
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
    private func initialize() async {
        phase = .initializing
        errorMessage = nil
        statusMessage = "Initializing LinkController..."

        do {
            let config = try await LinkControllerDemoBackendClient.fetchConfig()
            STPAPIClient.shared.publishableKey = config.publishableKey

            let cid = try await LinkControllerDemoBackendClient.fetchOrCreateCustomer(email: configuration.email)
            customerId = cid

            linkController = try await LinkController.create(
                configuration: .init(
                    supportedPaymentMethodTypes: Array(configuration.supportedPaymentMethodTypes),
                    merchantDisplayName: "Example, Inc."
                )
            )

            savedPaymentMethods = try await LinkControllerDemoBackendClient.listPaymentMethods(for: cid)

            phase = .ready
            statusTint = .secondary
            statusMessage = "LinkController initialized successfully"
        } catch {
            phase = .error(error.localizedDescription)
            statusMessage = nil
            errorMessage = "Failed to initialize: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func presentLinkFlow() async {
        guard isReady, let customerId else {
            errorMessage = "LinkController not ready"
            return
        }

        guard let rootViewController = findViewController() else {
            errorMessage = "Could not find root view controller"
            return
        }

        phase = .presenting
        errorMessage = nil
        statusMessage = "Presenting Link flow..."

        do {
            guard let activeController = linkController else {
                phase = .ready
                errorMessage = "LinkController not initialized"
                return
            }

            let result = try await activeController.present(
                email: configuration.email,
                phoneNumber: configuration.phone.isEmpty ? nil : configuration.phone,
                from: rootViewController
            )

            switch result {
            case .completed(let paymentMethod):
                switch configuration.intentMode {
                case .serverSetupIntent:
                    // PM selected — wait for the merchant to tap "Confirm & Save".
                    statusTint = .secondary
                    statusMessage = "Payment method selected. Tap \"Confirm & Save\" to attach it."
                    phase = .awaitingConfirmation(paymentMethod)
                case .sdkManaged:
                    statusMessage = "Saving payment method..."
                    do {
                        try await LinkControllerDemoBackendClient.attachPaymentMethod(
                            paymentMethod.stripeId,
                            toCustomer: customerId
                        )
                        print("**** Payment method created (ID: \(paymentMethod.stripeId), type: \(paymentMethod.type))")
                    } catch {
                        errorMessage = "Payment method created (ID: \(paymentMethod.stripeId)) but failed to save: \(error.localizedDescription)"
                    }
                    try? await refreshSavedPaymentMethods()
                    statusTint = .green
                    statusMessage = "Payment method saved!"
                    phase = .completed(paymentMethod)
                }
            case .canceled:
                statusMessage = "Present flow canceled"
                phase = .ready
            }
        } catch {
            phase = .ready
            errorMessage = "Present flow failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func confirmFlow() async {
        guard case .awaitingConfirmation = phase, let customerId else { return }

        guard let rootViewController = findViewController() else {
            errorMessage = "Could not find root view controller"
            return
        }

        guard let activeController = linkController else {
            errorMessage = "LinkController not initialized"
            return
        }

        phase = .confirming
        errorMessage = nil
        statusMessage = "Creating SetupIntent and confirming..."

        do {
            let secret = try await LinkControllerDemoBackendClient.createSetupIntent(customerId: customerId)
            setupIntentClientSecret = secret

            let confirmResult = try await activeController.confirmSetupIntent(
                clientSecret: secret,
                from: rootViewController
            )

            switch confirmResult {
            case .completed(let paymentMethod):
                try? await refreshSavedPaymentMethods()
                statusTint = .green
                statusMessage = "Payment method saved!"
                phase = .completed(paymentMethod)
            case .canceled:
                statusMessage = "Confirmation canceled"
                phase = .ready
            }
        } catch {
            phase = .ready
            errorMessage = "Confirmation failed: \(error.localizedDescription)"
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
        errorMessage = nil
        do {
            let response = try await LinkControllerDemoBackendClient.charge(
                paymentMethodId: pm.id,
                customerId: customerId
            )

            if response.code == "authentication_required", let secret = response.clientSecret {
                guard let vc = findViewController() else {
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
                statusTint = .yellow
                statusMessage = "Payment processing (ID: \(response.paymentIntentId))..."
                await pollPaymentIntentStatus(piId: response.paymentIntentId)
            } else {
                statusMessage = "Payment \(response.status) (ID: \(response.paymentIntentId))"
            }
        } catch {
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
        errorMessage = nil
        do {
            try await LinkControllerDemoBackendClient.detachPaymentMethod(pm.id)
            try await refreshSavedPaymentMethods()
            statusMessage = "Payment method removed"
        } catch {
            errorMessage = "Failed to remove payment method: \(error.localizedDescription)"
        }
    }
}

@available(iOS 16.0, *)
#Preview {
    var config = LinkControllerDemoConfiguration()
    config.email = "test@example.com"
    return LinkControllerDemoView(configuration: config)
}
