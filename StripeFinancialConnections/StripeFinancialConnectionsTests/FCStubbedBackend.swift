//
//  FCStubbedBackend.swift
//  StripeFinancialConnectionsTests
//
//  Created by Mat Schmid on 2024-07-05.
//

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeFinancialConnections

class FCStubbedBackend {
    static func stubSynchronize() {
        stub { request in
            request.url?.absoluteString.contains("/v1/financial_connections/sessions/synchronize") ?? false
        } response: { _ in
            let mockResponseData = try! FCSynchronizeResponseMock.rocketrides_demo.data()
            return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
        }
    }

    static func stubImages() {
        for imageMock in FCMockImage.allCases {
            stub { request in
                request.url?.absoluteString.contains(imageMock.stubUrl) ?? false
            } response: { _ in
                let mockResponseData = try! imageMock.data()
                return HTTPStubsResponse(data: mockResponseData, statusCode: 200, headers: nil)
            }
        }
    }
}

private class ClassForBundle {}

enum FCSynchronizeResponseMock: String, MockData {
    public typealias ResponseType = FinancialConnectionsSynchronize
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case rocketrides_demo = "FinancialConnectionsManifest_Demo"
}

enum FCMockImage: String, CaseIterable {
    public var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    public var stubUrl: String {
        "stripe://images/\(rawValue)"
    }

    public func data() throws -> Data {
        let url = bundle.url(forResource: rawValue, withExtension: "png")!
        return try Data(contentsOf: url)
    }

    case link = "link"
    case lock = "lock"
    case rocketDeliveries = "rocket-deliveries"
    case stripeLogo = "stripe-logo"
}
