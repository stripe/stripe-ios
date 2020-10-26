//
//  BackendAPIAdapter.swift
//  Basic Integration
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe
import PassKit

class MyAPIClient: NSObject, STPCustomerEphemeralKeyProvider {
    enum APIError: Error {
        case unknown

        var localizedDescription: String {
            switch self {
            case .unknown:
                return "Unknown error"
            }
        }
    }

    static let sharedClient = MyAPIClient()
    var baseURLString: String?
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }

    func createPaymentIntent(products: [Product], shippingMethod: PKShippingMethod?, country: String? = nil, completion: @escaping ((Result<String, Error>) -> Void)) {
        let url = self.baseURL.appendingPathComponent("create_payment_intent")
        var params: [String: Any] = [
            "metadata": [
                // example-mobile-backend allows passing metadata through to Stripe
                "payment_request_id": "B3E611D1-5FA1-4410-9CEC-00958A5126CB"
            ]
        ]
        params["products"] = products.map({ (p) -> String in
            return p.emoji
        })
        if let shippingMethod = shippingMethod {
            params["shipping"] = shippingMethod.identifier
        }
        params["country"] = country
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) as [String: Any]??),
                let secret = json?["secret"] as? String else {
                    completion(.failure(error ?? APIError.unknown))
                    return
            }
            completion(.success(secret))
        })
        task.resume()
    }

    func createCustomerKey(withAPIVersion apiVersion: String, completion: @escaping STPJSONResponseCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("ephemeral_keys")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [URLQueryItem(name: "api_version", value: apiVersion)]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) as [String: Any]??) else {
                completion(nil, error)
                return
            }
            completion(json, nil)
        })
        task.resume()
    }

}
