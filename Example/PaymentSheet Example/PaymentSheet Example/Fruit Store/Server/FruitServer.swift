//
//  FruitServer.swift
//  FruitStore

import Foundation
import AuthenticationServices

fileprivate let BackendAPIURL = URL(string: "https://fruitstore-backend.herokuapp.com")!

class FruitServer: Server {
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
        
        let params = ["user_id": appleIDCredential.user, "token": identityTokenString]
        callServer(endpoint: "apple_login", method: "POST", params: params) { result in
            guard let sessionToken = result["session_token"] as? String else {
                completion(.failure(.other))
                return
            }
            self.sessionToken = sessionToken
            completion(.success(sessionToken))
        }
    }

    func fetchGuestSessionToken(completion: @escaping (Result<String, ServerError>) -> Void) {
        callServer(endpoint: "guest_login", method: "POST") { result in
            guard let sessionToken = result["session_token"] as? String else {
                completion(.failure(.other))
                return
            }
            self.sessionToken = sessionToken
            completion(.success(sessionToken))
        }
    }

    func fetchCustomer(completion: @escaping (Result<Customer, ServerError>) -> Void) {
        guard let sessionToken = sessionToken else {
            completion(.failure(.tokenMissing))
            return
        }
        
        let params = ["session_token": sessionToken]
        callServer(endpoint: "customer", method: "GET", params: params) { result in
            guard let customer = Customer(result) else {
                completion(.failure(.serverError(error: result.description)))
                return
            }
            completion(.success(customer))
        }
    }

    func buy(fruit: Fruit, completion: @escaping (Result<Customer, ServerError>) -> Void) {
        guard let sessionToken = sessionToken else {
            completion(.failure(.tokenMissing))
            return
        }
        
        let params = ["session_token": sessionToken, "fruit": fruit.emoji]
        callServer(endpoint: "buy", method: "POST", params: params) { result in
            if let error = result["error"] as? String {
                // TODO: Replace this with an actual error code
                if error.contains("balance") {
                    completion(.failure(.insufficientFunds(coinsNeeded: 10)))
                    return
                }
            }
            guard let customer = Customer(result) else {
                completion(.failure(.serverError(error: result.description)))
                return
            }
            completion(.success(customer))
        }
    }

    func getRefillURL(completion: @escaping (Result<URL, ServerError>) -> Void) {
        guard let sessionToken = sessionToken else {
            completion(.failure(.tokenMissing))
            return
        }
        
        let params = ["session_token": sessionToken]
        callServer(endpoint: "refill_url", method: "GET", params: params) { result in
            guard let urlString = result["url"] as? String,
                  let url = URL(string: urlString) else {
                completion(.failure(.serverError(error: result.description)))
                return
            }
            completion(.success(url))
        }
    }

    func logout() {
        sessionToken = nil
    }

    private func callServer(endpoint: String, method: String, params: [String : Any] = [:], completion: @escaping ([String : Any]) -> Void) {
        var request = URLRequest(url: BackendAPIURL.appendingPathComponent(endpoint))
        request.httpMethod = method
        
//        if request.httpMethod == "POST" {
//            request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
//            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            request.addValue("application/json", forHTTPHeaderField: "Accept")
//        } else {
            var urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = params.map({ URLQueryItem(name: $0, value: $1 as? String)})
            request.url = urlComponents.url
//        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
          guard let unwrappedData = data,
                let json = try? JSONSerialization.jsonObject(with: unwrappedData, options: []) as? [String : Any] else {
            if let data = data {
                print("\(String(decoding: data, as: UTF8.self))")
            } else {
                print("\(error ?? NSError())")
            }
            return
          }
          
          DispatchQueue.main.async {
              if let error = json["error"] as? String {
                  if error == "Session is invalid." {
                      self.logout()
                  }
              }
            completion(json)
          }
        })
        task.resume()
    }
    
}

protocol Server {
    func fetchSessionToken(with appleIDCredential: ASAuthorizationAppleIDCredential, completion: @escaping (Result<String, ServerError>) -> Void)
    func fetchGuestSessionToken(completion: @escaping (Result<String, ServerError>) -> Void)
    func fetchCustomer(completion: @escaping (Result<Customer, ServerError>) -> Void)
    func buy(fruit: Fruit, completion: @escaping (Result<Customer, ServerError>) -> Void)
    func getRefillURL(completion: @escaping (Result<URL, ServerError>) -> Void)
    func logout()
}

enum ServerError: Error {
    case insufficientFunds(coinsNeeded: Int)
    case tokenMissing
    case serverError(error: String)
    case other
    
    var localizedDescription: String {
        switch self {
        case .insufficientFunds(let amount):
            return "You need \(amount) coins to buy this fruit."
        case .tokenMissing:
            return "This action requires authentication."
        case .serverError(let error):
            return "An error occurred when communicating with the server: \(error)"
        case .other:
            return "An error occurred."
        }
    }
}
