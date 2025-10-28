//
//  BackendModel.swift
//  AppClipExample (iOS)
//
//  Created by David Estes on 1/20/22.
//

import Foundation
import StripeApplePay

class BackendModel {
    // You can replace this with your own backend URL.
    // If you want to edit our backend, visit https://codesandbox.io/p/devbox/3c3ymr, login, and fork.
    static let backendAPIURL = URL(string: "https://stp-integration-tester-v3.stripedemos.com/")!

    static let returnURL = "stp-integration-tester://stripe-redirect"

    public static let shared = BackendModel()

    func fetchPaymentIntent(completion: @escaping (String?) -> Void) {
        let params = ["integration_method": "Apple Pay"]
        getAPI(method: "create_pi", params: params) { (json) in
            guard let paymentIntentClientSecret = json["paymentIntent"] as? String else {
                completion(nil)
                return
            }
            completion(paymentIntentClientSecret)
        }
    }

    func loadPublishableKey(completion: @escaping (String) -> Void) {
        let params = ["integration_method": "Apple Pay"]
        getAPI(method: "get_pub_key", params: params) { (json) in
          if let publishableKey = json["publishableKey"] as? String {
            completion(publishableKey)
          } else {
            assertionFailure("Could not fetch publishable key from backend")
          }
        }
    }

    private func getAPI(method: String, params: [String: Any] = [:], completion: @escaping ([String: Any]) -> Void) {
        var request = URLRequest(url: Self.backendAPIURL.appendingPathComponent(method))
        request.httpMethod = "POST"

        request.httpBody = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, _, error) in
          guard let unwrappedData = data,
                let json = try? JSONSerialization.jsonObject(with: unwrappedData, options: []) as? [String: Any] else {
            if let data = data {
                print("\(String(decoding: data, as: UTF8.self))")
            } else {
                print("\(error ?? NSError())")  // swiftlint:disable:this discouraged_direct_init
            }
            return
          }
          DispatchQueue.main.async {
            completion(json)
          }
        })
        task.resume()
    }
}
