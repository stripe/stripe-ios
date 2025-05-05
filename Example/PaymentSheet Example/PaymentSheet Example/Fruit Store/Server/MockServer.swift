//
//  MockServer.swift
//  FruitStore

import Foundation
import AuthenticationServices

class MockServer: Server {
    var customer: Customer = Customer(name: "David", wallet: 100, purchased: [], hasProSubscription: true)
    let fakeServerDelay = 0.1
    
    // The cached session token
    var sessionToken: String? {
        get {
            return UserDefaults.standard.string(forKey: SessionTokenKey)
        }
        set {
            return UserDefaults.standard.setValue(newValue, forKey: SessionTokenKey)
        }
    }
    let SessionTokenKey = "sessionToken"
    
    func fetchSessionToken(with appleIDCredential: ASAuthorizationAppleIDCredential, completion: @escaping (Result<String, ServerError>) -> Void) {
        guard let identityToken = appleIDCredential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            completion(.failure(.other))
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fakeServerDelay) {
            let sessionToken = "ABC123"
            self.sessionToken = sessionToken
            completion(.success(sessionToken))
        }
    }

    func fetchGuestSessionToken(completion: @escaping (Result<String, ServerError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + fakeServerDelay) {
            let sessionToken = "ABC123"
            self.sessionToken = sessionToken
            completion(.success(sessionToken))
        }
    }

    func fetchCustomer(completion: @escaping (Result<Customer, ServerError>) -> Void) {
        guard let sessionToken = sessionToken else {
            completion(.failure(.tokenMissing))
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fakeServerDelay) {
            completion(.success(self.customer))
        }
    }
    
    func buy(fruit: Fruit, completion: @escaping (Result<Customer, ServerError>) -> Void) {
        guard let sessionToken = sessionToken else {
            completion(.failure(.tokenMissing))
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + fakeServerDelay) {
            let price = 10
            if self.customer.wallet - price < 0 {
                completion(.failure(.insufficientFunds(coinsNeeded: price)))
            } else {
                self.customer.wallet = self.customer.wallet - 10
                self.customer.purchased.append(fruit)
                completion(.success(self.customer))
            }
        }
    }
    
    func getRefillURL(completion: @escaping (Result<URL, ServerError>) -> Void) {
        guard let sessionToken = sessionToken else {
            completion(.failure(.tokenMissing))
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fakeServerDelay) {
            completion(.success(URL(string: "https://buy.stripe.com/test_cN2g236nNebEaWc8wx")!))
        }
    }
    
    func logout() {
        sessionToken = nil
    }
    
    // For testing only
    func refillCoins() {
        customer.wallet = customer.wallet + 100
    }
}
