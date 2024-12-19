//
//  AppAttestService.swift
//  StripeCore
//

import DeviceCheck
import Foundation

@_spi(STP) public protocol AppAttestService {
    nonisolated var isSupported: Bool { get }
    func generateKey() async throws -> String
    func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data
    func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data

    /// Returns `true` if the attestation is from the development environment.
    /// If `false`, it's either from the production environment or invalid.
    func attestationDataIsDevelopmentEnvironment(_ data: Data) -> Bool
}

@_spi(STP) public class AppleAppAttestService: AppAttestService {
    @_spi(STP) public static var shared = AppleAppAttestService()

    // No one should initialize this directly, it's a wrapper around a system singleton
    private init() { }

    @_spi(STP) public var isSupported: Bool {
        if #available(iOS 14.0, *) {
            return DCAppAttestService.shared.isSupported
        } else {
            return false
        }
    }

    @_spi(STP) public func generateKey() async throws -> String {
        guard #available(iOS 14.0, *) else {
            stpAssertionFailure()
            throw StripeAttest.AttestationError.attestationNotSupported
        }
        return try await DCAppAttestService.shared.generateKey()
    }

    @_spi(STP) public func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        guard #available(iOS 14.0, *) else {
            stpAssertionFailure()
            throw StripeAttest.AttestationError.attestationNotSupported
        }
        return try await DCAppAttestService.shared.generateAssertion(keyId, clientDataHash: clientDataHash)
    }

    @_spi(STP) public func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        guard #available(iOS 14.0, *) else {
            stpAssertionFailure()
            throw StripeAttest.AttestationError.attestationNotSupported
        }
        return try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: clientDataHash)
    }

    @_spi(STP) public func attestationDataIsDevelopmentEnvironment(_ data: Data) -> Bool {
       let appAttestDevelopData = Data("appattestdevelop".utf8)
       return data.range(of: appAttestDevelopData) != nil
   }
}
