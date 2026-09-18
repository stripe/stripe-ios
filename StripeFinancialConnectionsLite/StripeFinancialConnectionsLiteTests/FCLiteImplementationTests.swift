//
//  FCLiteImplementationTests.swift
//  StripeFinancialConnectionsLiteTests
//
//  Created by Mat Schmid on 2025-03-28.
//

import Foundation
@_spi(STP) import StripeCore
@testable import StripeFinancialConnectionsLite
import XCTest

class FCLiteImplementationTests: XCTestCase {
    private class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool {
            true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }

        override func startLoading() {
            guard let requestHandler = Self.requestHandler else {
                XCTFail("Missing request handler.")
                return
            }
            let (response, data) = requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    func testFCLiteImplementationAvailable() {
        let FinancialConnectionsLiteImplementation: FinancialConnectionsSDKInterface.Type? =
            NSClassFromString("StripeFinancialConnectionsLite.FCLiteImplementation")
            as? FinancialConnectionsSDKInterface.Type
        XCTAssertNotNil(FinancialConnectionsLiteImplementation)
    }

    func testSynchronizeIncludesConsumerSessionClientSecretWhenDataPermissionsRequested() async throws {
        // Given an existing consumer and requested data permissions
        var apiClient = makeAPIClient()
        apiClient.consumerSessionClientSecret = "consumer_session_client_secret_123"
        apiClient.hasRequestedDataPermissions = true

        // When synchronizing
        let parameters = try await synchronizeParameters(apiClient: apiClient)

        // Then the consumer session client secret is included
        XCTAssertEqual(
            parameters["consumer_session_client_secret"],
            "consumer_session_client_secret_123"
        )
    }

    func testSynchronizeOmitsConsumerSessionClientSecretWithoutDataPermissions() async throws {
        // Given an existing consumer without requested data permissions
        var apiClient = makeAPIClient()
        apiClient.consumerSessionClientSecret = "consumer_session_client_secret_123"
        apiClient.hasRequestedDataPermissions = false

        // When synchronizing
        let parameters = try await synchronizeParameters(apiClient: apiClient)

        // Then the consumer session client secret is omitted
        XCTAssertNil(parameters["consumer_session_client_secret"])
    }

    private func makeAPIClient() -> FCLiteAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let backingAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        backingAPIClient.urlSession = URLSession(configuration: configuration)
        return FCLiteAPIClient(backingAPIClient: backingAPIClient)
    }

    private func synchronizeParameters(
        apiClient: FCLiteAPIClient
    ) async throws -> [String: String] {
        var requestParameters: [String: String] = [:]
        MockURLProtocol.requestHandler = { request in
            let body = request.bodyData.flatMap { String(data: $0, encoding: .utf8) }
            var components = URLComponents()
            components.query = body
            requestParameters = Dictionary(
                uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
            )

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let responseBody = """
                {
                  "manifest": {
                    "id": "fcsess_123",
                    "hosted_auth_url": "https://stripe.com/hosted",
                    "success_url": "https://stripe.com/success",
                    "cancel_url": "https://stripe.com/cancel",
                    "product": "bank_account",
                    "manual_entry_uses_microdeposits": false
                  }
                }
                """
            return (response, Data(responseBody.utf8))
        }
        defer {
            MockURLProtocol.requestHandler = nil
        }

        _ = try await apiClient.synchronize(
            clientSecret: "financial_connections_session_client_secret_123",
            returnUrl: nil,
            canUseNativeLink: false,
            secureWebviewFeatureFlagEnabled: false
        )
        return requestParameters
    }
}

private extension URLRequest {
    var bodyData: Data? {
        if let httpBody {
            return httpBody
        }
        guard let httpBodyStream else {
            return nil
        }

        let maxLength = 1024
        var data = Data()
        var buffer = Data(count: maxLength)
        httpBodyStream.open()
        buffer.withUnsafeMutableBytes { bufferPointer in
            let typedPointer = bufferPointer.bindMemory(to: UInt8.self)
            while httpBodyStream.hasBytesAvailable {
                let length = httpBodyStream.read(
                    typedPointer.baseAddress!,
                    maxLength: maxLength
                )
                guard length > 0 else {
                    break
                }
                data.append(typedPointer.baseAddress!, count: length)
            }
        }
        return data
    }
}
