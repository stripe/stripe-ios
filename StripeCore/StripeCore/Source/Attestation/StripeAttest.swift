//
//  StripeAttest.swift
//  StripeCore
//

import CryptoKit
import DeviceCheck
import Foundation
import UIKit

@_spi(STP) public class StripeAttest {
    /// Initialize a new StripeAttest object with the specified STPAPIClient.
    @_spi(STP) public convenience init(apiClient: STPAPIClient = .shared) {
        self.init(appAttestService: AppleAppAttestService.shared,
                  appAttestBackend: StripeAPIAttestationBackend(apiClient: apiClient), apiClient: apiClient)
    }

    /// Sign an assertion.
    /// Will create and attest a new device key if needed.
    @_spi(STP) public func assert() async throws -> Assertion {
        do {
            let assertion = try await _assert()
            let successAnalytic = GenericAnalytic(event: .assertionSucceeded, params: [:])
            STPAnalyticsClient.sharedClient.log(analytic: successAnalytic, apiClient: apiClient)
            return assertion
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .assertionFailed, error: error)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: apiClient)
            throw error
        }
    }

    // MARK: Public structs

    /// Contains the signed data and various information used to sign the request.
    @_spi(STP) public struct Assertion {
        /// The signed assertion data.
        @_spi(STP) public var assertionData: Data
        /// The `identifierForVendor` for the current app/device pair.
        @_spi(STP) public var deviceID: String
        /// The App ID (not fully qualified, it's missing the Team ID prefix)
        @_spi(STP) public var appID: String
        /// The key ID
        @_spi(STP) public var keyID: String

        /// A convenience function to return the fields used in an asserted request.
        @_spi(STP) public var requestFields: [String: String] {
            return [ "deviceId": deviceID,
                     "appID": appID,
                     "keyID": keyID,
                     "assertionData": assertionData.base64EncodedString(), ]
        }
    }

    @_spi(STP) public enum AttestationError: Error {
        /// Attestation is not supported on this device.
        case attestationNotSupported
        /// Device ID is unavailable.
        case noDeviceID
        /// App ID is unavailable.
        case noAppID
        /// Retried assertion, but it failed.
        case secondAssertionFailureAfterRetryingAttestation
        /// Can't attest any more keys today.
        case attestationRateLimitExceeded
        /// The challenge couldn't be converted to UTF-8 data.
        case invalidChallengeData
    }

    // MARK: - Internal

    // MARK: - Device-local settings
    enum DefaultsKeys: String {
        /// The ID of the attestation key stored in the keychain.
        case keyID = "STPAttestKeyID"
        /// The last date we generated an attestation key, used for rate limiting.
        case lastAttestedDate = "STPAttestKeyLastAttestedDate"
        /// Whether the current keyID key has been attested successfully.
        case successfullyAttested = "STPAttestKeySuccessfullyAttested"
    }

    private static var keyID: String? {
        get {
            UserDefaults.standard.string(forKey: DefaultsKeys.keyID.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.keyID.rawValue)
        }
    }

    private static var successfullyAttested: Bool {
        get {
            UserDefaults.standard.bool(forKey: DefaultsKeys.successfullyAttested.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.successfullyAttested.rawValue)
        }
    }

    private static var lastAttestedDate: Date? {
        get {
            UserDefaults.standard.object(forKey: DefaultsKeys.lastAttestedDate.rawValue) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DefaultsKeys.lastAttestedDate.rawValue)
        }
    }

    init(appAttestService: AppAttestService, appAttestBackend: StripeAttestBackend?, apiClient: STPAPIClient) {
        self.appAttestService = appAttestService
        self.appAttestBackend = appAttestBackend ?? StripeAPIAttestationBackend(apiClient: apiClient)
        self.apiClient = STPAPIClient.shared
    }

    /// A wrapper for the DCAppAttestService service.
    var appAttestService: AppAttestService
    /// A network backend for the /challenge and /attest endpoints.
    var appAttestBackend: StripeAttestBackend
    /// The API client to use for network requests
    var apiClient: STPAPIClient

    /// The minimum time between key generation attempts.
    /// This is a safeguard against generating keys too often, as each key generation
    /// permanently increases a counter for the device/app pair.
    /// We expect each device/app pair to generate one key *ever*.
    /// If this rate limit is being hit, something is wrong.
    private static let minDurationBetweenKeyGenerationAttempts: TimeInterval = 60 * 60 * 24 // 24 hours

    /// Attest the current device key. Only perform this once per device key.
    /// You should not call this directly, it'll be called automatically during assert.
    /// Returns nothing on success, throws on failure.
    func attest() async throws {
        do {
            try await _attest()
            let successAnalytic = GenericAnalytic(event: .attestationSucceeded, params: [:])
            STPAnalyticsClient.sharedClient.log(analytic: successAnalytic, apiClient: apiClient)
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .attestationFailed, error: error)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: apiClient)
            throw error
        }
    }

    func _assert() async throws -> Assertion {
        let keyId = try await self.getOrCreateKeyID()

        if !Self.successfullyAttested {
            // We haven't attested yet, so do that first.
            try await self.attest()
        }

        let challenge = try await getChallenge()

        let deviceId = try getDeviceID()
        let appId = try getAppID()

        let assertion = try await generateAssertion(keyId: keyId, challenge: challenge)
        return Assertion(assertionData: assertion, deviceID: deviceId, appID: appId, keyID: keyId)
    }

    func _attest() async throws {
        // It's dangerous to attest, as it increments a permanent counter for the device.
        // First, make sure the last time we called this is more than 24 hours away from now.
        // (Either in the future or the past, who knows what people are doing with their clocks)
        if let lastGenerated = StripeAttest.lastAttestedDate, abs(lastGenerated.timeIntervalSinceNow) < Self.minDurationBetweenKeyGenerationAttempts {
            throw AttestationError.attestationRateLimitExceeded
        }

        let keyId = try await self.getOrCreateKeyID()
        let challenge = try await getChallenge()
        guard let challengeData = challenge.data(using: .utf8) else {
            throw AttestationError.invalidChallengeData
        }
        let hash = Data(SHA256.hash(data: challengeData))

        let deviceId = try getDeviceID()
        let appId = try getAppID()

        do {
            Self.lastAttestedDate = Date()
            let attestation = try await appAttestService.attestKey(keyId, clientDataHash: hash)
            try await appAttestBackend.attest(appId: appId, deviceId: deviceId, keyId: keyId, attestation: attestation)
            // Store the successful attestation
            Self.successfullyAttested = true
        } catch {
            // If error is DCErrorInvalidKey (3) and the domain is DCErrorDomain,
            // we need to generate a new key as the key has already been attested or is otherwise corrupt.
            let error = error as NSError
            if error.domain == DCErrorDomain && error.code == DCError.invalidKey.rawValue {
                resetKey()
            }
            // For other errors, just report them as an analytic and throw. We'll want to retry attestation with the same key.
            throw error
        }
    }

    /// Returns the device's current key ID, creating one if needed.
    /// Throw an error if the device doesn't support attestation, or if key generation fails.
    private func getOrCreateKeyID() async throws -> String {
        guard appAttestService.isSupported else {
            throw AttestationError.attestationNotSupported
        }
        if let keyId = Self.keyID {
            return keyId
        }
        // If we don't have a key, generate one.
        return try await self.createKey()
    }

    @_spi(STP) public func resetKey() {
        Self.keyID = nil
        Self.successfullyAttested = false
    }

    private func createKey() async throws -> String {
        let keyId = try await appAttestService.generateKey()
        // Save the Key ID, and that the key is not attested.
        Self.keyID = keyId
        Self.successfullyAttested = false
        return keyId
    }

    func getAppID() throws -> String {
        if let appID = Bundle.main.bundleIdentifier {
            return appID
        }
        throw AttestationError.noAppID
    }

    func getDeviceID() throws -> String {
        if let deviceID = UIDevice.current.identifierForVendor?.uuidString {
            return deviceID
        }
        throw AttestationError.noDeviceID
    }

    /// Get a challenge from the backend.
    func getChallenge() async throws -> String {
        let keyID = try await self.getOrCreateKeyID()
        return try await appAttestBackend.getChallenge(appId: getAppID(), deviceId: getDeviceID(), keyId: keyID)
    }

    /// Generate the assertion data from a key and challenge.
    private func generateAssertion(keyId: String, challenge: String, retryAfterReattestingIfNeeded: Bool = true) async throws -> Data {
        // We're just signing the challenge for now.
        // The expected format is the SHA256 hash of the JSON-encoded dictionary.
        let assertionDictionary = [ "challenge": challenge ]
        let assertionData = try JSONSerialization.data(withJSONObject: assertionDictionary,
                                                       // Sort our keys: It's important that the JSON is
                                                       // the same on the backend and frontend!
                                                       options: [.sortedKeys])
        let assertionDataHash = Data(SHA256.hash(data: assertionData))
        do {
            return try await appAttestService.generateAssertion(keyId, clientDataHash: assertionDataHash)
        } catch {
            // If error is DCErrorInvalidKey (3) and the domain is DCErrorDomain,
            // then the key is either unattested or corrupted.
            let error = error as NSError
            if error.domain == DCErrorDomain && error.code == DCError.invalidKey.rawValue {
                if retryAfterReattestingIfNeeded {
                    // We'll try to attest again, maybe our initial attestation was unsuccessful?
                    // `DCError.invalidKey` could mean a lot of things, unfortunately.
                    // If this doesn't work, then in `attest()` we'll deem the key to be corrupted
                    // and throw it out.
                    try await attest()
                    // Once we've successfully re-attested, we'll try one more time to do the assertion.
                    return try await generateAssertion(keyId: keyId, challenge: challenge, retryAfterReattestingIfNeeded: false)
                } else {
                    // If it *still* fails, something is super broken.
                    // Give up for now, we'll try again tomorrow.
                    throw AttestationError.secondAssertionFailureAfterRetryingAttestation
                }
            }
            // For other errors, we'll want to retry attestation later with the same key.
            throw error
        }
    }
}
