//
//  StripeAttestBackend.swift
//  StripeCore
//

import Foundation

@_spi(InternalOnlyAPI) public protocol StripeAttestBackend {
    func getChallenge(appId: String, deviceId: String, keyId: String) async throws -> StripeChallengeResponse
    func attest(appId: String, deviceId: String, keyId: String, attestation: Data) async throws
}

@_spi(InternalOnlyAPI) public struct StripeChallengeResponse: Decodable {
    let challenge: String
    let initial_attestation_required: Bool
}

@_spi(InternalOnlyAPI) public class StripeAPIAttestationBackend: StripeAttestBackend {
    let apiClient: STPAPIClient

    @_spi(InternalOnlyAPI) public init(apiClient: STPAPIClient) {
        self.apiClient = apiClient
    }

    @_spi(InternalOnlyAPI) public func attest(appId: String, deviceId: String, keyId: String, attestation: Data) async throws {
        let _: EmptyResponse = try await withCheckedThrowingContinuation { continuation in
            apiClient.post(resource: "mobile_sdk_attestation/ios_attest", parameters: ["app_id": appId, "device_id": deviceId, "key_id": keyId, "attestation_object": attestation.base64EncodedString()]) { result in
                continuation.resume(with: result)
            }
        }
        // If attestation succeeds, we can proceed. Otherwise we'll throw an error above.
    }

    @_spi(InternalOnlyAPI) public func getChallenge(appId: String, deviceId: String, keyId: String) async throws -> StripeChallengeResponse {
        let challengeResponse: StripeChallengeResponse = try await withCheckedThrowingContinuation { continuation in
            apiClient.post(resource: "mobile_sdk_attestation/ios_challenge", parameters: ["app_id": appId, "device_id": deviceId, "key_id": keyId]) { result in
                continuation.resume(with: result)
            }
        }
        return challengeResponse
    }
}
