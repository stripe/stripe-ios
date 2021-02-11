//
//  BackendModel.swift
//  IntegrationTester
//
//  Created by David Estes on 2/10/21.
//

import Foundation
import Stripe

class BackendModel {
    static let backendAPIURL = URL(string: "https://stripe-integration-tester.glitch.me")!
    static let returnURL = "stp-integration-tester://stripe-redirect"
    public static let shared = BackendModel()
    
    func fetchPaymentIntent(completion: @escaping (STPPaymentIntentParams?) -> Void) {
        getAPI(method: "checkout") { (json) in
            guard let paymentIntentClientSecret = json["paymentIntent"] as? String else {
                completion(nil)
                return
            }
            completion(STPPaymentIntentParams(clientSecret: paymentIntentClientSecret))
        }
    }

    func fetchSetupIntent(completion: @escaping (STPSetupIntentConfirmParams?) -> Void)  {
        getAPI(method: "setup") { (json) in
            guard let setupIntentClientSecret = json["setupIntent"] as? String else {
                completion(nil)
                return
            }
            completion(STPSetupIntentConfirmParams(clientSecret: setupIntentClientSecret))
        }
    }
    
    private func getAPI(method: String, completion: @escaping ([String : Any]) -> Void) {
        var request = URLRequest(url: Self.backendAPIURL.appendingPathComponent(method))
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
          guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let publishableKey = json["publishableKey"] as? String else {
            // Handle error
            return
          }
          STPAPIClient.shared.publishableKey = publishableKey
          DispatchQueue.main.async {
            completion(json)
          }
        })
        task.resume()
    }
}

class MySIBackendModel : ObservableObject {
  @Published var paymentStatus: STPPaymentHandlerActionStatus?
  @Published var intentParams: STPSetupIntentConfirmParams?
  @Published var lastPaymentError: NSError?

  func preparePaymentIntent() {
    BackendModel.shared.fetchSetupIntent { sip in
        sip?.returnURL = BackendModel.returnURL
        self.intentParams = sip
    }
  }

  func onCompletion(status: STPPaymentHandlerActionStatus, si: STPSetupIntent?, error: NSError?) {
    self.paymentStatus = status
    self.lastPaymentError = error
  }
}

class MyPIBackendModel : ObservableObject {
  @Published var paymentStatus: STPPaymentHandlerActionStatus?
  @Published var paymentIntentParams: STPPaymentIntentParams?
  @Published var lastPaymentError: NSError?

  func preparePaymentIntent() {
    BackendModel.shared.fetchPaymentIntent { pip in
        pip?.returnURL = BackendModel.returnURL
        self.paymentIntentParams = pip
    }
  }

  func onCompletion(status: STPPaymentHandlerActionStatus, pi: STPPaymentIntent?, error: NSError?)
  {
    self.paymentStatus = status
    self.lastPaymentError = error
  }
}
