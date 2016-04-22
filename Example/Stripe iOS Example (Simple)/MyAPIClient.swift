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
    @objc var cards: [STPCard]? = []
    @objc var selectedCard: STPCard?
    @objc var shippingAddress: STPAddress?

    let baseURL: NSURL
    let customerID: String
    let session: NSURLSession

    init(baseURL: String, customerID: String) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 5
        self.session = NSURLSession(configuration: configuration)
        self.baseURL = NSURL(string: baseURL) ?? NSURL(string: "http://example.com")!
        self.customerID = customerID
        super.init()
    }

    func decodeData(data: NSData?) -> (selectedCard: STPCard?, cards: [STPCard]?)? {
        guard let json = data?.JSON else { return nil }
        if let cardsJSON = json["cards"] as? [[String: AnyObject]],
            selectedCardJSON = json["selected_card"] as? [String: AnyObject] {
            let selectedCard = STPCard.decodedObjectFromAPIResponse(selectedCardJSON)
            let cards = cardsJSON.flatMap { STPCard.decodedObjectFromAPIResponse($0) }
            return (selectedCard, cards)
        }
        return nil
    }

    func decodeResponse(response: NSURLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? NSHTTPURLResponse
            where httpResponse.statusCode != 200 {
            return error ?? NSError.networkingError(httpResponse.statusCode)
        }
        return nil
    }

    func completeCharge(source: STPSource, amount: Int, completion: STPErrorBlock) {
        let path = "charge"
        let url = self.baseURL.URLByAppendingPathComponent(path)
        let params: [String: AnyObject] = [
            "stripe_token": source.stripeID,
            "amount": amount,
            "customer": self.customerID
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
    
    @objc func retrieveCards(completion: STPCardCompletionBlock) {
        let path = "cards"
        let url = self.baseURL.URLByAppendingPathComponent(path)
        let params = [ "customer": self.customerID ]
        let request = NSURLRequest.request(url, method: .GET, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(self.selectedCard, self.cards, error)
                    return
                }
                if let (selectedCard, cards) = self.decodeData(data) {
                    self.selectedCard = selectedCard
                    self.cards = cards
                    completion(self.selectedCard, self.cards, nil)
                }
            }
        }
        task.resume()
    }

    @objc func selectCard(card: STPCard, completion: STPCardCompletionBlock) {
        let path = "select_source"
        let url = self.baseURL.URLByAppendingPathComponent(path)
        let params = [
            "customer": self.customerID,
            "source": card.stripeID,
        ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(self.selectedCard, self.cards, error)
                    return
                }
                if let (selectedCard, cards) = self.decodeData(data) {
                    self.selectedCard = selectedCard
                    self.cards = cards
                    completion(self.selectedCard, self.cards, nil)
                }
            }
        }
        task.resume()
    }
    
    @objc func addToken(token: STPToken, completion: STPCardCompletionBlock) {
        let path = "add_token"
        let url = self.baseURL.URLByAppendingPathComponent(path)
        let params = [
            "customer": self.customerID,
            "stripe_token": token.stripeID,
            ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = self.decodeResponse(urlResponse, error: error) {
                    completion(self.selectedCard, self.cards, error)
                    return
                }
                if let (selectedCard, cards) = self.decodeData(data) {
                    self.selectedCard = selectedCard
                    self.cards = cards
                    completion(self.selectedCard, self.cards, nil)
                }
            }
        }
        task.resume()
    }

}
