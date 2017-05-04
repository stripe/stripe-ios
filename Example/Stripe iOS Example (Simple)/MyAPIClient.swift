//
//  BackendAPIAdapter.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

class MyAPIClient: NSObject, STPResourceKeyProvider {

    static let sharedClient = MyAPIClient()
    let session: URLSession
    var baseURLString: String? = nil
    var defaultSource: STPCard? = nil
    var sources: [STPCard] = []

    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: configuration)
        super.init()
    }

    func decodeResponse(_ response: URLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? HTTPURLResponse
            , httpResponse.statusCode != 200 {
            return error ?? NSError.networkingError(httpResponse.statusCode)
        }
        return error
    }

    func completeCharge(_ result: STPPaymentResult, amount: Int, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set baseURLString to your Heroku URL in CheckoutViewController.swift"
                ])
            completion(error)
            return
        }
        let path = "charge"
        let url = baseURL.appendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source": result.source.stripeID as AnyObject,
            "amount": amount as AnyObject
        ]
        let request = URLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }

    func retrieveKey(_ completion: @escaping STPResourceKeyCompletionBlock) {
        let expires = Date().addingTimeInterval(60)
        let response: [String: Any] = [
            "contents": "sk_test_5RuiSbuDuzhua8zWiMCG0QT0",
            "expires": expires.timeIntervalSince1970
        ]
        let key = STPResourceKey.decodedObject(fromAPIResponse: response)
        completion(key, nil)
    }

}
