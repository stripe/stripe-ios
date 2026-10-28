//
//  AppAttestService.swift
//  StripeCore
//

import DeviceCheck
import Foundation

@_spi(InternalOnlyAPI) public protocol AppAttestService {
    nonisolated var isSupported: Bool { get }
    func generateKey() async throws -> String
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data

    /// Returns `true` if the attestation is from the development environment.
    /// If `false`, it's either from the production environment or invalid.
    func attestationDataIsDevelopmentEnvironment(_ data: Data) -> Bool
}

@_spi(InternalOnlyAPI) public class AppleAppAttestService: AppAttestService {
    @_spi(InternalOnlyAPI) public static var shared = AppleAppAttestService()

    // No one should initialize this directly, it's a wrapper around a system singleton
    private init() { }

    @_spi(InternalOnlyAPI) public var isSupported: Bool {
        return DCAppAttestService.shared.isSupported
    }

    @_spi(InternalOnlyAPI) public func generateKey() async throws -> String {
        return try await DCAppAttestService.shared.generateKey()
    }

    @_spi(InternalOnlyAPI) public func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        return try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)
    }

    @_spi(InternalOnlyAPI) public func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        return try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
    }

    @_spi(InternalOnlyAPI) public func attestationDataIsDevelopmentEnvironment(_ data: Data) -> Bool {
       let appAttestDevelopData = Data("appattestdevelop".utf8)
       return data.range(of: appAttestDevelopData) != nil
   }
}
