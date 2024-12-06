//
//  StripeAttestBackend.swift
//  StripeCore
//

import Foundation

@_spi(STP) public protocol StripeAttestBackend {
    func getChallenge(appId: String, deviceId: String, keyId: String) async throws -> String
    func attest(appId: String, deviceId: String, keyId: String, attestation: Data) async throws
}

@_spi(STP) public class StripeAPIAttestationBackend: StripeAttestBackend {
    let apiClient: STPAPIClient

    @_spi(STP) public init(apiClient: STPAPIClient) {
        self.apiClient = apiClient
    }

    public func attest(appId: String, deviceId: String, keyId: String, attestation: Data) async throws {
        stpAssertionFailure("Not implemented")
    }

    public func getChallenge(appId: String, deviceId: String, keyId: String) async throws -> String {
        stpAssertionFailure("Not implemented")
        return ""
    }
}
