//
//  BackendAPIAdapter.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

class MyAPIClient: NSObject, STPBackendAPIAdapter {

    static let sharedClient = MyAPIClient()
    let session: NSURLSession
    var baseURLString: String? = nil
    var defaultSource: STPCard? = nil
    var sources: [STPCard] = []

    override init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 5
        self.session = NSURLSession(configuration: configuration)
        super.init()
    }

    func decodeResponse(response: NSURLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? NSHTTPURLResponse
            where httpResponse.statusCode != 200 {
            return error ?? NSError.networkingError(httpResponse.statusCode)
        }
        return error
    }

    func completeCharge(result: STPPaymentResult, amount: Int, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString) else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set baseURLString to your Heroku URL in CheckoutViewController.swift"
                ])
            completion(error)
            return
        }
        let path = "charge"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source": result.source.stripeID,
            "amount": amount
        ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
    @objc func retrieveCustomer(completion: STPCustomerCompletionBlock) {
        guard let key = Stripe.defaultPublishableKey() where !key.containsString("#") else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set stripePublishableKey to your account's test publishable key in CheckoutViewController.swift"
            ])
            completion(nil, error)
            return
        }
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString) else {
            // This code is just for demo purposes - in this case, if the example app isn't properly configured, we'll return a fake customer just so the app works.
            let customer = STPCustomer(stripeID: "cus_test", defaultSource: self.defaultSource, sources: self.sources)
            completion(customer, nil)
            return
        }
        let path = "/customer"
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = NSURLRequest.request(url, method: .GET, params: [:])
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                let deserializer = STPCustomerDeserializer(data: data, urlResponse: urlResponse, error: error)
                if let error = deserializer.error {
                    completion(nil, error)
                    return
                } else if let customer = deserializer.customer {
                    completion(customer, nil)
                }
            }
        }
        task.resume()
    }
    
    @objc func selectDefaultCustomerSource(source: STPSource, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString) else {
            if let token = source as? STPToken {
                self.defaultSource = token.card
            }
            completion(nil)
            return
        }
        let path = "/customer/default_source"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [
            "source": source.stripeID,
        ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
    @objc func attachSourceToCustomer(source: STPSource, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString) else {
            if let token = source as? STPToken, card = token.card {
                self.sources.append(card)
                self.defaultSource = card
            }
            completion(nil)
            return
        }
        let path = "/customer/sources"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [
            "source": source.stripeID,
            ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }

}
