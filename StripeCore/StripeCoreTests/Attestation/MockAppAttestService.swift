//
//  MockAppAttestService.swift
//  StripeCore
//
//  Created by David Estes on 12/2/24.
//

import CryptoKit
import DeviceCheck
@testable @_spi(STP) import StripeCore
import UIKit

actor MockAppAttestService: AppAttestService {
    @_spi(STP) public static var shared = MockAppAttestService()

    @_spi(STP) public nonisolated var isSupported: Bool {
        if #available(iOS 14.0, *) {
            return true
        } else {
            return false
        }
    }

    var shouldFailKeygenWithError: Error?
    var shouldFailAssertionWithError: Error?
    var shouldFailAttestationWithError: Error?
    var attestationUsingDevelopmentEnvironment: Bool = false

    func setShouldFailKeygenWithError(_ error: Error?) async {
        shouldFailKeygenWithError = error
    }

    func setShouldFailAssertionWithError(_ error: Error?) async {
        shouldFailAssertionWithError = error
    }

    func setShouldFailAttestationWithError(_ error: Error?) async {
        shouldFailAttestationWithError = error
    }

    func setAttestationUsingDevelopmentEnvironment(_ value: Bool) async {
        attestationUsingDevelopmentEnvironment = value
    }

    var keys: [String: FakeKey] = [:]

    struct FakeKey: Codable {
        var id: String = UUID().uuidString
        var counter: Int = 0
    }

    @_spi(STP) public func generateKey() async throws -> String {
        if let error = shouldFailKeygenWithError {
            throw error
        }
        let key = FakeKey()
        keys[key.id] = key
        return key.id
    }

    @_spi(STP) public func generateAssertion(_ keyId: String, clientDataHash: Data) async throws -> Data {
        guard var key = keys[keyId] else {
            // Throw the same error that the real service would throw
            throw NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        }
        if let error = shouldFailAssertionWithError {
            throw error
        }
        key.counter += 1
        keys[key.id] = key
        // Our fake assertion is the keyID glommed onto the clientDataHash
        return key.id.data(using: .utf8)! + clientDataHash
    }

    @_spi(STP) public func attestKey(_ keyId: String, clientDataHash: Data) async throws -> Data {
        guard var key = keys[keyId] else {
            // Throw the same error that the real service would throw
            throw NSError(domain: DCErrorDomain, code: DCError.invalidKey.rawValue, userInfo: nil)
        }
        if let error = shouldFailAttestationWithError {
            throw error
        }
        key.counter += 1
        keys[key.id] = key
        // Generate a fake attestion
        let attestation = ["keyID": key.id, "counter": key.counter, "clientDataHash": clientDataHash.base64EncodedString(), "isDevelopmentEnvironment": attestationUsingDevelopmentEnvironment] as [String: Any]
        return try JSONSerialization.data(withJSONObject: attestation)
    }

    @_spi(STP) public nonisolated func attestationDataIsDevelopmentEnvironment(_ data: Data) -> Bool {
        let decodedKey = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        return decodedKey["isDevelopmentEnvironment"] as! Bool
    }
}

@_spi(STP) public class MockAttestBackend: StripeAttestBackend {
    var storedChallenge: String?
    var keyHasBeenAttested: [String: Bool] = [:]

    public func attest(appId: String, deviceId: String, keyId: String, attestation: Data) async throws {
        // Decode the attestation data (it's a JSON dictionary)
        let attestationDict = try JSONSerialization.jsonObject(with: attestation) as! [String: Any]

        // Confirm the challenge exists in our challenge list
        guard let challenge = storedChallenge else {
            // No challenge available, throw an error
            throw NSError(domain: "com.stripe.internal-error", code: 403, userInfo: ["error": "No challenge available"])
        }

        // Confirm the Key ID is correct
        let hash = Data(SHA256.hash(data: challenge.data(using: .utf8)!)).base64EncodedString()
        guard hash == attestationDict["clientDataHash"] as? String else {
            // Hash is incorrect, throw an error
            throw NSError(domain: "com.stripe.internal-error", code: 403, userInfo: ["error": "Incorrect hash"])
        }

        keyHasBeenAttested[keyId] = true

        // Remove the challenge
        storedChallenge = nil
    }

    public func assertionTest(assertion: StripeAttest.Assertion) async throws {
        guard let challenge = storedChallenge else {
            // No challenge available, throw an error
            throw NSError(domain: "com.stripe.internal-error", code: 403, userInfo: ["error": "No challenge available"])
        }

        let requestFieldsToHash = [ "challenge": challenge ]
        let clientDataToHash = try JSONSerialization.data(withJSONObject: requestFieldsToHash)
        print(String(data: clientDataToHash, encoding: .utf8)!)
        let clientDataHash = Data(SHA256.hash(data: clientDataToHash))

        // Our fake assertion is the keyID glommed onto the clientDataHash
        let expectedAssertionData = assertion.keyID.data(using: .utf8)! + clientDataHash
        guard expectedAssertionData == assertion.assertionData else {
            throw NSError(domain: "com.stripe.internal-error", code: 403, userInfo: ["error": "Assertion data does not match expected data"])
        }
        // Clean up the challenge
        storedChallenge = nil
    }

    public func getChallenge(appId: String, deviceId: String, keyId: String) async throws -> StripeCore.StripeChallengeResponse {
        // Confirm the AppID and DeviceID are correct
        let currentDeviceId = await UIDevice.current.identifierForVendor!.uuidString

        guard appId == Bundle.main.bundleIdentifier && deviceId == currentDeviceId else {
            throw NSError(domain: "com.stripe.internal-error", code: 403, userInfo: ["error": "Device ID or Bundle ID incorrect"])
        }

        // Generate a random challenge:
        let challenge = UUID().uuidString.data(using: .utf8)!.base64EncodedString()
        storedChallenge = challenge
        return .init(challenge: challenge, initial_attestation_required: !(keyHasBeenAttested[keyId] ?? false))
    }

}
