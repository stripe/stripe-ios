//
//  CryptoOnrampMockData.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 10/28/25.
//

import Foundation
@_spi(STP) import StripeCore
import StripeCoreTestUtils

@testable @_spi(CryptoOnrampAlpha) import StripeCryptoOnramp

// note: This class is to find the test bundle
private class ClassForBundle {}

// MARK: Responses

enum RetrieveKYCInfoResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = RetrieveKYCInfoResponse

    case retrieveKYCInfoResponse_200 = "RetrieveKYCInfoResponse_200"
}

enum RefreshKYCInfoResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = EmptyResponse

    case refreshKYCInfoResponse_200 = "RefreshKYCInfoResponse_200"
}

enum RetrieveMissingIdentifiersResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = ComplianceIdentifierRequirements

    case retrieveMissingIdentifiersResponse_200 = "RetrieveMissingIdentifiersResponse_200"
}

enum SubmitIdentifiersResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = SubmitIdentifiersResult

    case submitIdentifiersResponse_Invalid_200 = "SubmitIdentifiersResponse_Invalid_200"
    case submitIdentifiersResponse_Valid_200 = "SubmitIdentifiersResponse_Valid_200"
}

enum RetrieveCRSCARFDeclarationResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = CRSCARFDeclaration

    case retrieveCRSCARFDeclarationResponse_200 = "RetrieveCRSCARFDeclarationResponse_200"
}

enum ConfirmCRSCARFDeclarationResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = EmptyResponse

    case confirmCRSCARFDeclarationResponse_200 = "ConfirmCRSCARFDeclarationResponse_200"
}

enum StripeAPIErrorResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = StripeAPIErrorResponse

    case appAttestationFailure = "AppAttestationFailure_400"
}
