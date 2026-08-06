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

enum RetrieveUserAttestationResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = UserAttestation

    case retrieveUserAttestationResponse_200 = "RetrieveUserAttestationResponse_200"
}

enum ConfirmUserAttestationResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = EmptyResponse

    case confirmUserAttestationResponse_200 = "ConfirmUserAttestationResponse_200"
}

enum WalletOwnershipChallengeResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = WalletOwnershipChallenge

    case walletOwnershipChallengeResponse_200 = "WalletOwnershipChallengeResponse_200"
}

enum SubmitWalletOwnershipSignatureResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = CryptoConsumerWallet

    case submitWalletOwnershipSignatureResponse_200 = "SubmitWalletOwnershipSignatureResponse_200"
}

enum StripeAPIErrorResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = StripeAPIErrorResponse

    case appAttestationFailure = "AppAttestationFailure_400"
}
