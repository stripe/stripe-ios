//
//  CheckoutSessionDiagnostics.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 8/11/26.
//

@_spi(InternalOnlyAPI) import StripeCore
import SwiftUI

@MainActor
final class CheckoutSessionDiagnostics: ObservableObject {
    struct Request: Identifiable, Sendable {
        let requestID: String
        let method: String
        let path: String
        let date: Date

        var id: String { requestID }

        var endpoint: String {
            "\(method) \(path)"
        }

        var displayName: String {
            guard path.contains("/checkout_client/") else {
                return "Stripe API request"
            }
            switch path.split(separator: "/").last {
            case "init":
                return "Initialize session"
            case "confirm":
                return "Confirm session"
            case "update":
                return "Update session"
            case "retrieve":
                return "Retrieve session"
            case "poll":
                return "Poll session"
            default:
                return "Stripe API request"
            }
        }
    }

    @Published private(set) var requests: [Request] = []

    private var requestCapture: CheckoutRequestCapture?
    private var captureGeneration = UUID()

    /// Returns a copy of the shared API client that records Stripe request IDs for this cart.
    func makeAPIClient(checkoutClientRequestDelay: TimeInterval) -> STPAPIClient {
        requests.removeAll()
        let captureGeneration = UUID()
        self.captureGeneration = captureGeneration

        let apiClient = STPAPIClient.shared.makeCopy()
        let requestCapture = CheckoutRequestCapture(
            forwardingConfiguration: apiClient.urlSession.configuration,
            checkoutClientRequestDelay: checkoutClientRequestDelay
        ) { [weak self] response in
            let request = Request(
                requestID: response.requestID,
                method: response.method,
                path: response.path,
                date: Date()
            )
            Task { @MainActor in
                self?.record(request, captureGeneration: captureGeneration)
            }
        }
        self.requestCapture = requestCapture
        apiClient.urlSession = URLSession(configuration: requestCapture.sessionConfiguration)
        return apiClient
    }

    private func record(_ request: Request, captureGeneration: UUID) {
        guard captureGeneration == self.captureGeneration else {
            return
        }
        guard !requests.contains(where: { $0.requestID == request.requestID }) else {
            return
        }
        requests.insert(request, at: 0)
    }
}
