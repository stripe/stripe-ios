//
//  APIStubbedTestCase.swift
//  StripeiOS Tests
//
//  Created by David Estes on 9/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs
@testable import Stripe
@testable @_spi(STP) import StripeCore

/* A test case offering a custom STPAPIClient with manual JSON stubbing. */
class APIStubbedTestCase: XCTestCase {
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
    }

    
    func stubbedAPIClient() -> STPAPIClient {
        let apiClient = STPAPIClient()
        let urlSessionConfig = URLSessionConfiguration.default
        HTTPStubs.setEnabled(true, for: urlSessionConfig)
        apiClient.urlSession = URLSession(configuration: urlSessionConfig)
        return apiClient
    }
}
