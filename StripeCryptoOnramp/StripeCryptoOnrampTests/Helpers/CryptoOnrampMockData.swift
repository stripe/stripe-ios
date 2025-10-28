//
//  CryptoOnrampMockData.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/28/25.
//

import Foundation
import StripeCoreTestUtils

@testable import StripeCryptoOnramp

// note: This class is to find the test bundle
private class ClassForBundle {}

// MARK: Responses

enum RetrieveKYCInfoResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = RetrieveKYCInfoResponse

    case retrieveKYCInfoResponse_200 = "RetrieveKYCInfoResponse_200"
}
