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

    let baseURLString: String?
    let customerID: String?
    let session: NSURLSession

    init(baseURL: String?, customerID: String?) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 5
        self.session = NSURLSession(configuration: configuration)
        self.baseURLString = baseURL
        self.customerID = customerID
        super.init()
    }

    func decodeData(data: NSData?) -> (selectedCard: STPCard?, cards: [STPCard]?)? {
        guard let json = data?.JSON else { return nil }
        if let cardsJSON = json["cards"] as? [[String: AnyObject]] {
            let selectedCardJSON = json["selected_card"] as? [String: AnyObject]
            let selectedCard = decodeCard(selectedCardJSON)
            let cards = cardsJSON.flatMap(decodeCard)
            return (selectedCard, cards)
        }
        return nil
    }
    
    func decodeCard(json: [String: AnyObject]?) -> STPCard? {
        guard let json = json,
            cardID = json["id"] as? String,
            brand = json["brand"] as? String,
            last4 = json["last4"] as? String,
            expMonth = json["exp_month"] as? UInt,
            expYear = json["exp_year"] as? UInt,
            funding = json["funding"] as? String
            else { return nil }
        return STPCard(ID: cardID, brand: STPCard.brandFromString(brand), last4: last4, expMonth: expMonth, expYear: expYear, funding: STPCard.fundingFromString(funding))
    }

    func decodeResponse(response: NSURLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? NSHTTPURLResponse
            where httpResponse.statusCode != 200 {
            return error ?? NSError.networkingError(httpResponse.statusCode)
        }
        return error
    }

    func completeCharge(result: STPPaymentResult, amount: Int, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(nil)
            return
        }
        let path = "charge"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source": result.source.stripeID,
            "amount": amount,
            "customer": customerID
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
    
    @objc func retrieveCustomerCards(completion: STPCardCompletionBlock) {
        guard let key = Stripe.defaultPublishableKey() where !key.containsString("#") else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set stripePublishableKey to your account's test publishable key in CheckoutViewController.swift"
            ])
            completion(nil, nil, error)
            return
        }
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(nil, [], nil)
            return
        }
        let path = "/customers/\(customerID)/cards"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [ "customer": customerID ]
        let request = NSURLRequest.request(url, method: .GET, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(nil, [], error)
                    return
                }
                if let (selectedCard, cards) = self.decodeData(data) {
                    completion(selectedCard, cards, nil)
                }
            }
        }
        task.resume()
    }
    
    @objc func selectDefaultCustomerSource(source: STPSource, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(nil)
            return
        }
        let path = "/customers/\(customerID)/select_source"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [
            "customer": customerID,
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
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(nil)
            return
        }
        let path = "/customers/\(customerID)/sources"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [
            "customer": customerID,
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
    
    func deleteCard(card: STPCard, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(nil)
            return
        }
        let path = "/customers/\(customerID)/cards/\(card)"
        let url = baseURL.URLByAppendingPathComponent(path)
        let request = NSURLRequest.request(url, method: .DELETE, params: [:])
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
