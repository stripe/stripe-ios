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
    
    var inMemoryCards: [STPCard] = []

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
        return error
    }

    func completeCharge(source: STPSource, amount: Int, completion: STPErrorBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(nil)
            return
        }
        let path = "charge"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source": source.stripeID,
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
    
    @objc func retrieveCards(completion: STPCardCompletionBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(self.inMemoryCards.last, self.inMemoryCards, nil)
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

    @objc func selectCard(card: STPCard, completion: STPCardCompletionBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            completion(card, self.inMemoryCards, nil)
            return
        }
        let path = "select_source"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [
            "customer": customerID,
            "source": card.stripeID,
        ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
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
    
    @objc func addToken(token: STPToken, completion: STPCardCompletionBlock) {
        guard let baseURLString = baseURLString, baseURL = NSURL(string: baseURLString), customerID = customerID else {
            if let card = token.card {
                self.inMemoryCards.append(card)
                completion(card, self.inMemoryCards, nil)
            } else {
                completion(nil, [], nil)
            }
            return
        }
        let path = "/customers/\(customerID)/sources"
        let url = baseURL.URLByAppendingPathComponent(path)
        let params = [
            "customer": customerID,
            "source": token.stripeID,
            ]
        let request = NSURLRequest.request(url, method: .POST, params: params)
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

}
