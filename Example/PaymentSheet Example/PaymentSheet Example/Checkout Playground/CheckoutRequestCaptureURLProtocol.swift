//
//  CheckoutRequestCaptureURLProtocol.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 8/11/26.
//

import Foundation

/// Adds request-ID observation to a single URL session without changing the configuration used
/// to perform its requests.
final class CheckoutRequestCapture {
    /// Metadata for a completed Stripe API request.
    struct Response: Sendable {
        let requestID: String
        let method: String
        let path: String
    }

    let sessionConfiguration: URLSessionConfiguration

    private let captureID = UUID().uuidString

    init(
        forwardingConfiguration: URLSessionConfiguration,
        didReceiveResponse: @escaping @Sendable (Response) -> Void
    ) {
        guard let sessionConfiguration = forwardingConfiguration.copy() as? URLSessionConfiguration else {
            preconditionFailure("URLSessionConfiguration must support copying")
        }

        CheckoutRequestCaptureRegistry.register(
            captureID: captureID,
            forwardingConfiguration: forwardingConfiguration,
            didReceiveResponse: didReceiveResponse
        )

        var additionalHeaders = sessionConfiguration.httpAdditionalHeaders ?? [:]
        additionalHeaders[CheckoutRequestCaptureURLProtocol.captureIDHeader] = captureID
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        sessionConfiguration.protocolClasses = [CheckoutRequestCaptureURLProtocol.self]
            + (sessionConfiguration.protocolClasses ?? [])
        self.sessionConfiguration = sessionConfiguration
    }

    deinit {
        CheckoutRequestCaptureRegistry.unregister(captureID: captureID)
    }
}

private enum CheckoutRequestCaptureRegistry {
    struct Context {
        let forwardingConfiguration: URLSessionConfiguration
        let didReceiveResponse: @Sendable (CheckoutRequestCapture.Response) -> Void
    }

    private static let lock = NSLock()
    private static var contexts: [String: Context] = [:]

    static func register(
        captureID: String,
        forwardingConfiguration: URLSessionConfiguration,
        didReceiveResponse: @escaping @Sendable (CheckoutRequestCapture.Response) -> Void
    ) {
        lock.lock()
        contexts[captureID] = Context(
            forwardingConfiguration: forwardingConfiguration,
            didReceiveResponse: didReceiveResponse
        )
        lock.unlock()
    }

    static func unregister(captureID: String) {
        lock.lock()
        contexts[captureID] = nil
        lock.unlock()
    }

    static func context(for captureID: String) -> Context? {
        lock.lock()
        let context = contexts[captureID]
        lock.unlock()
        return context
    }
}

private class CheckoutRequestCaptureURLProtocol: URLProtocol {
    static let captureIDHeader = "X-Checkout-Playground-Capture-ID"

    private static let handledRequestKey = "CheckoutPlaygroundHandledRequest"

    private enum State {
        case loading
        case stopped
        case completed
    }

    private let stateLock = NSLock()
    private var state = State.loading
    private var dataTask: URLSessionDataTask?
    private var forwardingSession: URLSession?

    override class func canInit(with request: URLRequest) -> Bool {
        return request.value(forHTTPHeaderField: captureIDHeader) != nil
            && URLProtocol.property(forKey: handledRequestKey, in: request) == nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let captureID = request.value(forHTTPHeaderField: Self.captureIDHeader),
              let context = CheckoutRequestCaptureRegistry.context(for: captureID),
              let forwardedRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        forwardedRequest.setValue(nil, forHTTPHeaderField: Self.captureIDHeader)
        URLProtocol.setProperty(true, forKey: Self.handledRequestKey, in: forwardedRequest)

        let forwardingSession = URLSession(configuration: context.forwardingConfiguration)
        self.forwardingSession = forwardingSession
        dataTask = forwardingSession.dataTask(with: forwardedRequest as URLRequest) { [weak self] data, response, error in
            guard let self, beginCompletion() else { return }
            defer { forwardingSession.finishTasksAndInvalidate() }

            guard let response else {
                client?.urlProtocol(self, didFailWithError: error ?? URLError(.badServerResponse))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               let requestID = httpResponse.value(forHTTPHeaderField: "request-id") {
                context.didReceiveResponse(
                    CheckoutRequestCapture.Response(
                        requestID: requestID,
                        method: forwardedRequest.httpMethod ?? "REQUEST",
                        path: forwardedRequest.url?.path ?? "Stripe API"
                    )
                )
            }

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        }
        dataTask?.resume()
    }

    override func stopLoading() {
        guard stopIfLoading() else { return }
        dataTask?.cancel()
        forwardingSession?.invalidateAndCancel()
    }

    private func beginCompletion() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard state == .loading else { return false }
        state = .completed
        return true
    }

    private func stopIfLoading() -> Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard state == .loading else { return false }
        state = .stopped
        return true
    }
}
