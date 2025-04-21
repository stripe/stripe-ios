//
//  StripeAttest.swift
//  StripeCore
//

import CryptoKit
import DeviceCheck
import Foundation
import UIKit

@_spi(STP) public actor StripeAttest {
    /// Initialize a new StripeAttest object with the specified STPAPIClient.
    @_spi(STP) public init(apiClient: STPAPIClient = .shared) {
        self.init(appAttestService: AppleAppAttestService.shared,
                  appAttestBackend: StripeAPIAttestationBackend(apiClient: apiClient),
                  apiClient: apiClient)
    }

    /// Sign an assertion.
    /// Will create and attest a new device key if needed.
    /// Returns an AssertionHandle, which must be called after the network request completes (with success or failure) in order to unblock future assertions.
    @_spi(STP) public func assert() async throws -> AssertionHandle {
        // Make sure we only process one assertion at a time, until the latest
        if assertionInProgress {
            try await withCheckedThrowingContinuation { continuation in
                assertionWaiters.append(continuation)
            }
        }
        assertionInProgress = true

        do {
            let assertion = try await _assert()
            let successAnalytic = GenericAnalytic(event: .assertionSucceeded, params: [:])
            if let apiClient {
                STPAnalyticsClient.sharedClient.log(analytic: successAnalytic, apiClient: apiClient)
            }
            return AssertionHandle(assertion: assertion, stripeAttest: self)
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .assertionFailed, error: error)
            if let apiClient {
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: apiClient)
            }
            if apiClient?.isTestmode ?? false {
                // In testmode, we can provide a test assertion even if the real assertion fails
                return await AssertionHandle(assertion: testmodeAssertion(), stripeAttest: self)
            } else {
                // Clean up the continuation, as we're not returning it as an AssertionHandle
                assertionCompleted()
                throw error
            }
        }
    }

    /// Determines if the current device is able to sign requests.
    /// If the device has not attested previously, we will create a key and attest it.
    /// If `true`, the device is ready for attestation. If `false`, attestation is not possible.
    @_spi(STP) public func prepareAttestation() async -> Bool {
        do {
            if !successfullyAttested {
                // We haven't attested yet, so do that first.
                try await self.attest()
            }

            return successfullyAttested
        } catch {
            return false
        }
    }

    /// Inform StripeAttest of an error received in response to an assertion.
    /// The key will be reset.
    @_spi(STP) public func receivedAssertionError(_ error: Error) {
        let resetKeyAnalytic = ErrorAnalytic(event: .resetKeyForAssertionError, error: error)
        if let apiClient {
            STPAnalyticsClient.sharedClient.log(analytic: resetKeyAnalytic, apiClient: apiClient)
        }
        resetKey()
    }

    /// Returns whether the device is capable of performing attestation.
    @_spi(STP) nonisolated public var isSupported: Bool {
        return appAttestService.isSupported
    }

    @_spi(STP) public static func isLinkAssertionError(error: Error) -> Bool {
        if let error = error as? StripeCore.StripeError,
           case let .apiError(apiError) = error,
           apiError.code == "link_failed_to_attest_request" {
            return true
        }
        return false
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
            return [ "device_id": deviceID,
                     "app_id": appID,
                     "key_id": keyID,
                     "ios_assertion_object": assertionData.base64EncodedString(), ]
        }
    }

    @_spi(STP) public enum AttestationError: String, Error {
        /// Attestation is not supported on this device.
        case attestationNotSupported = "attestation_not_supported"
        /// Device ID is unavailable.
        case noDeviceID = "no_device_id"
        /// App ID is unavailable.
        case noAppID = "no_app_id"
        /// Retried assertion, but it failed.
        case secondAssertionFailureAfterRetryingAttestation = "second_assertion_failure_after_retrying_attestation"
        /// Can't attest any more keys today.
        case attestationRateLimitExceeded = "attestation_rate_limit_exceeded"
        /// The challenge couldn't be converted to UTF-8 data.
        case invalidChallengeData = "invalid_challenge_data"
        /// The backend asked us not to attest
        case shouldNotAttest = "should_not_attest"
        /// The backend asked us to attest, but the key is already attested
        case shouldAttestButKeyIsAlreadyAttested = "should_attest_but_key_is_already_attested"
        /// A publishable key was not set
        case noPublishableKey = "no_publishable_key"
    }

    // MARK: - Internal

    // MARK: - Device-local settings
    enum SettingsKeys: String {
        /// The ID of the attestation key stored in the keychain.
        case keyID = "STPAttestKeyID"
        /// The last date we generated an attestation key, used for rate limiting.
        case lastAttestedDate = "STPAttestKeyLastAttestedDate"
        /// Whether the current keyID key has been attested successfully.
        case successfullyAttested = "STPAttestKeySuccessfullyAttested"
    }

    private var storedKeyID: String? {
        get {
            UserDefaults.standard.string(forKey: defaultsKeyForSetting(.keyID))
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultsKeyForSetting(.keyID))
        }
    }

    private var successfullyAttested: Bool {
        get {
            UserDefaults.standard.bool(forKey: defaultsKeyForSetting(.successfullyAttested))
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultsKeyForSetting(.successfullyAttested))
        }
    }

    private var lastAttestedDate: Date? {
        get {
            UserDefaults.standard.object(forKey: defaultsKeyForSetting(.lastAttestedDate)) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultsKeyForSetting(.lastAttestedDate))
        }
    }

    /// The key to use for storing an attestation key in NSUserDefaults.
    func defaultsKeyForSetting(_ setting: SettingsKeys) -> String {
        var key = "\(setting.rawValue):\(apiClient?.publishableKey ?? "unknown")"
        if let stripeAccount = apiClient?.stripeAccount {
            key += ":\(stripeAccount)"
        }
        return key
    }

    init(appAttestService: AppAttestService, appAttestBackend: StripeAttestBackend?, apiClient: STPAPIClient) {
        self.appAttestService = appAttestService
        self.appAttestBackend = appAttestBackend ?? StripeAPIAttestationBackend(apiClient: apiClient)
        self.apiClient = apiClient
    }

    /// A wrapper for the DCAppAttestService service.
    /// Marked as nonisolated as it can not be reassigned during the lifetime
    /// of StripeAttest, and isolation is handled by the AppAttestService itself
    /// (Either DCAppAttestService or our MockAppAttestService)
    nonisolated let appAttestService: AppAttestService
    /// A network backend for the /challenge and /attest endpoints.
    let appAttestBackend: StripeAttestBackend
    /// The API client to use for network requests
    weak var apiClient: STPAPIClient?

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
        if let existingTask = attestationTask {
            return try await existingTask.value
        }

        let task = Task<Void, Error> {
            try await _attest()
            let successAnalytic = GenericAnalytic(event: .attestationSucceeded, params: [:])
            if let apiClient {
                STPAnalyticsClient.sharedClient.log(analytic: successAnalytic, apiClient: apiClient)
            }
        }
        attestationTask = task
        defer { attestationTask = nil } // Clear the task after it's done
        do {
            try await task.value
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .attestationFailed, error: error)
            if let apiClient {
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: apiClient)
            }
            throw error
        }
    }
    private var attestationTask: Task<Void, Error>?

    private var assertionInProgress: Bool = false
    private var assertionWaiters: [CheckedContinuation<Void, Error>] = []

    func _assert() async throws -> Assertion {
        let keyId = try await self.getOrCreateKeyID()

        if !successfullyAttested {
            // We haven't attested yet, so do that first.
            try await self.attest()
        }

        let challenge = try await getChallenge()

        // If the backend claims that attestation is required, but we already have an attested key,
        // something has gone wrong.
        if challenge.initial_attestation_required {
            // Reset the key, we'll try again next time:
            resetKey()
            throw AttestationError.shouldAttestButKeyIsAlreadyAttested
        }

        let deviceId = try await getDeviceID()
        let appId = try getAppID()

        let assertion = try await generateAssertion(keyId: keyId, challenge: challenge.challenge)
        return Assertion(assertionData: assertion, deviceID: deviceId, appID: appId, keyID: keyId)
    }

    func _attest() async throws {
        // It's dangerous to attest, as it increments a permanent counter for the device.
        // First, make sure the last time we called this is more than 24 hours away from now.
        // (Either in the future or the past, who knows what people are doing with their clocks)
        if let lastGenerated = lastAttestedDate, abs(lastGenerated.timeIntervalSinceNow) < Self.minDurationBetweenKeyGenerationAttempts {
            throw AttestationError.attestationRateLimitExceeded
        }

        let keyId = try await self.getOrCreateKeyID()
        let challenge = try await getChallenge()
        // If the backend claims that attestation isn't required, we should not attempt it.
        guard challenge.initial_attestation_required else {
            // And reset the key, as something has gone wrong.
            // The server thinks we've attested, but we think we haven't.
            resetKey()
            throw AttestationError.shouldNotAttest
        }
        guard let challengeData = challenge.challenge.data(using: .utf8) else {
            throw AttestationError.invalidChallengeData
        }
        let hash = Data(SHA256.hash(data: challengeData))

        let deviceId = try await getDeviceID()
        let appId = try getAppID()

        do {
            let attestation = try await appAttestService.attestKey(keyId, clientDataHash: hash)
            if !appAttestService.attestationDataIsDevelopmentEnvironment(attestation) {
                // We only need to limit attestations in production.
                // Being more relaxed about this also helps with users switching between
                // a developer-signed app (which may be in the development attest environment)
                // and a TestFlight/App Store/Enterprise app (which is always in the production attest environment)
                lastAttestedDate = Date()
            }
            try await appAttestBackend.attest(appId: appId, deviceId: deviceId, keyId: keyId, attestation: attestation)
            // Store the successful attestation
            successfullyAttested = true
        } catch {
            // If error is DCErrorInvalidKey (3) and the domain is DCErrorDomain,
            // we need to generate a new key as the key has already been attested or is otherwise corrupt.
            let error = error as NSError
            if error.domain == DCErrorDomain && error.code == DCError.invalidKey.rawValue {
                resetKey()
                let resetKeyAnalytic = ErrorAnalytic(event: .resetKeyForAttestationError, error: error)
                if let apiClient {
                    STPAnalyticsClient.sharedClient.log(analytic: resetKeyAnalytic, apiClient: apiClient)
                }
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
        guard apiClient?.publishableKey != nil else {
            throw AttestationError.noPublishableKey
        }
        if let keyId = storedKeyID {
            return keyId
        }
        // If we don't have a key, generate one.
        return try await self.createKey()
    }

    @_spi(STP) public func resetKey() {
        storedKeyID = nil
        successfullyAttested = false
    }

    private func createKey() async throws -> String {
        let keyId = try await appAttestService.generateKey()
        // Save the Key ID, and that the key is not attested.
        storedKeyID = keyId
        successfullyAttested = false
        return keyId
    }

    func getAppID() throws -> String {
        if let appID = Bundle.main.bundleIdentifier {
            return appID
        }
        throw AttestationError.noAppID
    }

    func getDeviceID() async throws -> String {
        if let deviceID = await UIDevice.current.identifierForVendor?.uuidString {
            return deviceID
        }
        throw AttestationError.noDeviceID
    }

    /// Get a challenge from the backend.
    func getChallenge() async throws -> StripeChallengeResponse {
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

    // MARK: Assertion concurrency

    // Called when an assertion handle is completed or times out
    @_spi(STP) public func assertionCompleted() {
        assertionInProgress = false

        // Resume the next waiter if there is one
        if !assertionWaiters.isEmpty {
            let nextContinuation = assertionWaiters.removeFirst()
            nextContinuation.resume()
        }
    }

    private func testmodeAssertion() async -> Assertion {
        Assertion(assertionData: Data(bytes: [0x01, 0x02, 0x03], count: 3),
                  deviceID: (try? await getDeviceID()) ?? "test-device-id",
                  appID: (try? getAppID()) ?? "com.example.test",
                  keyID: "TestKeyID")
    }
}

extension StripeAttest {
    public class AssertionHandle {
        public let assertion: Assertion
        private weak var stripeAttest: StripeAttest?

        init(assertion: Assertion, stripeAttest: StripeAttest) {
            self.assertion = assertion
            self.stripeAttest = stripeAttest
        }

        // Must be called by the caller when done with the assertion
        public func complete() {
            guard let stripeAttest = stripeAttest else {
                stpAssertionFailure("StripeAttest was deallocated before the assertion was completed")
                return
            }

            Task {
                await stripeAttest.assertionCompleted()
            }
        }
    }
}
