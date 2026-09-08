//
//  FCLiteApiClientTests.swift
//  StripeFinancialConnectionsLiteTests
//

@_spi(STP) import StripeCore
@testable @_spi(STP) import StripeFinancialConnectionsLite
import XCTest

private extension URLRequest {
    // The URL loading system converts `httpBody` into `httpBodyStream` before handing
    // the request to a `URLProtocol`, so both need to be checked to recover the body.
    var capturedBody: Data? {
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
        buffer.withUnsafeMutableBytes { bufferPtr in
            let bufferTypedPtr = bufferPtr.bindMemory(to: UInt8.self)
            while httpBodyStream.hasBytesAvailable {
                let length = httpBodyStream.read(bufferTypedPtr.baseAddress!, maxLength: maxLength)
                if length <= 0 {
                    break
                }
                data.append(bufferTypedPtr.baseAddress!, count: length)
            }
        }
        return data
    }
}

class FCLiteApiClientTests: XCTestCase {
    private enum TestError: Error {
        case sampleError
    }

    private class MockURLProtocol: URLProtocol {
        static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

        override class func canInit(with request: URLRequest) -> Bool {
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let requestHandler = Self.requestHandler else {
                XCTFail("Missing request handler.")
                return
            }

            do {
                let (response, data) = try requestHandler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {}
    }

    private func makeApiClient() -> FCLiteAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let stpAPIClient = STPAPIClient(publishableKey: "pk_test_123")
        stpAPIClient.urlSession = URLSession(configuration: configuration)
        return FCLiteAPIClient(backingAPIClient: stpAPIClient)
    }

    func testSynchronizeIncludesPreCollectedConsentWhenProvided() async {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            throw TestError.sampleError
        }
        defer {
            MockURLProtocol.requestHandler = nil
        }

        _ = try? await makeApiClient().synchronize(
            clientSecret: "las_client_secret_123",
            returnUrl: nil,
            canUseNativeLink: false,
            secureWebviewFeatureFlagEnabled: false,
            preCollectedConsent: FinancialConnectionsPreCollectedConsent(consent: "fccons_123")
        )

        let body = capturedRequest?.capturedBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(body?.contains("pre_collected_consent[consent]=fccons_123"), true)
    }

    func testSynchronizeOmitsPreCollectedConsentWhenNil() async {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            throw TestError.sampleError
        }
        defer {
            MockURLProtocol.requestHandler = nil
        }

        _ = try? await makeApiClient().synchronize(
            clientSecret: "las_client_secret_123",
            returnUrl: nil,
            canUseNativeLink: false,
            secureWebviewFeatureFlagEnabled: false,
            preCollectedConsent: nil
        )

        let body = capturedRequest?.capturedBody.flatMap { String(data: $0, encoding: .utf8) }
        XCTAssertEqual(body?.contains("pre_collected_consent"), false)
    }
}
