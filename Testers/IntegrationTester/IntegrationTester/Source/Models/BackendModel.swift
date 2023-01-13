//
//  BackendModel.swift
//  IntegrationTester
//
//  Created by David Estes on 2/10/21.
//

import Foundation
import IntegrationTesterCommon
import Stripe

class BackendModel {
    // You can replace this with your own backend URL.
    // Visit https://glitch.com/edit/#!/stripe-integration-tester and click "remix".
    static let backendAPIURL = URL(string: "https://stripe-integration-tester.glitch.me")!

    static let returnURL = "stp-integration-tester://stripe-redirect"

    public static let shared = BackendModel()

    func fetchPaymentIntent(integrationMethod: IntegrationMethod = .card, completion: @escaping (STPPaymentIntentParams?) -> Void) {
        let params = ["integration_method": integrationMethod.rawValue]
        getAPI(method: "create_pi", params: params) { (json) in
            guard let paymentIntentClientSecret = json["paymentIntent"] as? String else {
                completion(nil)
                return
            }
            completion(STPPaymentIntentParams(clientSecret: paymentIntentClientSecret))
        }
    }

    func fetchSetupIntent(params: [String: Any] = [:], completion: @escaping (STPSetupIntentConfirmParams?) -> Void)  {
        getAPI(method: "setup", params: params) { (json) in
            guard let setupIntentClientSecret = json["setupIntent"] as? String else {
                completion(nil)
                return
            }
            completion(STPSetupIntentConfirmParams(clientSecret: setupIntentClientSecret))
        }
    }

    func loadPublishableKey(integrationMethod: IntegrationMethod = .card, completion: @escaping (String) -> Void) {
        let params = ["integration_method": integrationMethod.rawValue]
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
                let json = try? JSONSerialization.jsonObject(with: unwrappedData, options: []) as? [String: Any],
                let publishableKey = json["publishableKey"] as? String else {
            if let data = data {
                print("\(String(decoding: data, as: UTF8.self))")
            } else {
                print("\(error ?? NSError())")  // swiftlint:disable:this discouraged_direct_init
            }
            return
          }

          // Your app will generally only use one publishable key. In this example app, we use a variety of
          // different Stripe accounts based in different countries, so we'll want to set the publishable key
          // each time we set up a new PaymentIntent.
          STPAPIClient.shared.publishableKey = publishableKey

          DispatchQueue.main.async {
            completion(json)
          }
        })
        task.resume()
    }
}
