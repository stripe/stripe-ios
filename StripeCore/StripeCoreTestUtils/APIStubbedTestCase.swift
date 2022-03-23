//
//  APIStubbedTestCase.swift
//  StripeCoreTestUtils
//
//  Created by David Estes on 9/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import XCTest
import OHHTTPStubs
@testable @_spi(STP) import StripeCore

/* A test case offering a custom STPAPIClient with manual JSON stubbing. */
open class APIStubbedTestCase: XCTestCase {
    open override func setUp() {
        super.setUp()

        // Stubs are evaluated in the reverse order that they are added, so if the network is hit and no other stub is matched, raise an exception
        stub(condition: { request in
            return true
        }) { request in
            XCTFail("Attempted to hit the live network at \(request.url?.path ?? "")")
            return HTTPStubsResponse()
        }
    }
    public override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    
    public func stubbedAPIClient() -> STPAPIClient {
        let apiClient = STPAPIClient()
        let urlSessionConfig = URLSessionConfiguration.default
        HTTPStubs.setEnabled(true, for: urlSessionConfig)
        apiClient.urlSession = URLSession(configuration: urlSessionConfig)
        return apiClient
    }
}
