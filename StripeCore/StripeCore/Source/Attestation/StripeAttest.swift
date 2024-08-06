//
//  StripeAttest.swift
//  StripeCore
//
//  Created by David Estes on 7/29/24.
//

import Foundation
import CryptoKit
import DeviceCheck

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
    
    func resetKey() {
        UserDefaults.standard.set(nil, forKey: Self.keyPrefName)
    }
    
    @_spi(STP) public func genKeys() {

        // Continue with server access.
        
    }
    
    @_spi(STP) public func attest() async {
        guard #available(iOS 14.0, *),
              DCAppAttestService.shared.isSupported,
              let keyId = await self.getKeyID()
        else {
            return // Don't do anything
        }
        let service = DCAppAttestService.shared

        let challenge = "abc123"
        let hash = Data(SHA256.hash(data: challenge.data(using: .utf8)!))

        do {
            let attestation = try await service.attestKey(keyId, clientDataHash: hash)
            print(attestation)
            // Send the attestation object to your server for verification.
        } catch {
//             If error is 3, we need to generate a new key, as the key has already been attested or is otherwise corrupt.
            // Rate limit these attempts
            resetKey()
            print(error)
            // Failed
        }
        await self.assert()
    }
    
    func assert() async {
        guard #available(iOS 14.0, *),
              DCAppAttestService.shared.isSupported,
              let keyId = await self.getKeyID()
        else {
            return // Don't do anything
        }
        let service = DCAppAttestService.shared

        let challenge = "abc123"
        let request = [ "action": "getGameLevel",
                        "levelId": "1234",
                        "challenge": challenge ]
        guard let clientData = try? JSONEncoder().encode(request) else { return }
        let clientDataHash = Data(SHA256.hash(data: clientData))
        do {
            let attestation = try await service.generateAssertion(keyId, clientDataHash: clientDataHash)
            print(attestation)
            // Send the attestation object to your server for verification.
        } catch {
            print(error)
            // Failed
        }
        
    }
}
