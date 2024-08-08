//
//  StripeAttest.swift
//  StripeCore
//
//  Created by David Estes on 7/29/24.
//

import Foundation
import CryptoKit
import DeviceCheck
import UIKit

@_spi(STP) public class StripeAttest {
    @_spi(STP) public static let shared = StripeAttest()
    
    private static let keyPrefName = "STPAttestKey"

    func getKeyID() async -> String? {
        if let keyId = UserDefaults.standard.string(forKey: Self.keyPrefName) {
            return keyId
        }
        // Otherwise generate one (IF APP ATTESTATION IS ALLOWED! ADD A CHECK TO PREVENT THSI FROM LOOPING)
        guard #available(iOS 14.0, *),
              DCAppAttestService.shared.isSupported
        else {
            return nil // Don't do anything
        }
        let service = DCAppAttestService.shared
        // Perform key generation and attestation.
//        let hashedEmailAddress = SHA256.hash(data: "jane@test.com".data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined()
        
        // Dangerous to call this!
        do {
            let keyId = try await service.generateKey()
            UserDefaults.standard.set(keyId, forKey: Self.keyPrefName)
            return keyId
        } catch {
            print(error)
            return nil
        }
    }
    
    @_spi(STP) public func resetKey() {
        UserDefaults.standard.set(nil, forKey: Self.keyPrefName)
    }
    
    @_spi(STP) public func genKeys() {

        // Continue with server access.
        
    }
    
    func getChallenge() async -> Data {
        let url = URL(string: "https://funny-observant-antler.glitch.me/challenge")!
        let deviceId = await UIDevice.current.identifierForVendor!.uuidString
        let requestParams = [ "deviceId": deviceId ]
        let clientData = try! JSONSerialization.data(withJSONObject: requestParams)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = clientData

        let (data, _) = try! await URLSession.shared.data(for: request)
        Swift.assert(data.count == 16)
        return data
    }
    
    @_spi(STP) public func attest() async {
        guard #available(iOS 14.0, *),
              DCAppAttestService.shared.isSupported,
              let keyId = await self.getKeyID()
        else {
            return // Don't do anything
        }
        let service = DCAppAttestService.shared

        let challenge = await getChallenge()
        let hash = Data(SHA256.hash(data: challenge))

        do {
            let attestation = try await service.attestKey(keyId, clientDataHash: hash)
            print(attestation)
            // Send the attestation object to your server for verification.
            let deviceId = await UIDevice.current.identifierForVendor!.uuidString
            let requestParams = [ "deviceId": deviceId,
                                  "challenge": challenge.base64EncodedString(),
                            "attestation": attestation.base64EncodedString() ]
            let clientData = try! JSONSerialization.data(withJSONObject: requestParams)
            let url = URL(string: "https://funny-observant-antler.glitch.me/attest")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = clientData
            let (data, _) = try! await URLSession.shared.data(for: request)
            print(data)
        } catch {
//             If error is 3, we need to generate a new key, as the key has already been attested or is otherwise corrupt.
            // Rate limit these attempts
            resetKey()
            print(error)
            // Failed
        }
//        await self.assert()
    }
    
    @_spi(STP) public func assert() async {
        guard #available(iOS 14.0, *),
              DCAppAttestService.shared.isSupported,
              let keyId = await self.getKeyID()
        else {
            return // Don't do anything
        }
        let service = DCAppAttestService.shared

        let challenge = await getChallenge()
        let deviceId = await UIDevice.current.identifierForVendor!.uuidString
        let request = [ "action": "getGameLevel",
                        "levelId": "1234",
                        "deviceId": deviceId,
                        "challenge": challenge.base64EncodedString() ]
        let clientData = try! JSONSerialization.data(withJSONObject: request)
        let clientDataHash = Data(SHA256.hash(data: clientData))
        do {
            let assertion = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
            print(assertion)
            let url = URL(string: "https://funny-observant-antler.glitch.me/assert")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(assertion.base64EncodedString(), forHTTPHeaderField: "X-Stripe-Apple-Assertion")
            request.httpBody = clientData
            let (data, _) = try! await URLSession.shared.data(for: request)
            print(String(data: data, encoding: .utf8)!)

            // Send the attestation object to your server for verification.
        } catch {
            print(error)
            // Failed
        }
        
    }
}

struct AttestationRequest: Codable {
    let attestation: String
}
