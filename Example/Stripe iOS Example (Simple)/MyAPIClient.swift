//
//  BackendAPIAdapter.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe
import Alamofire

class MyAPIClient: NSObject, STPBackendAPIAdapter {

    static let sharedClient = MyAPIClient()
    var baseURLString: String? = nil
    var baseURL: URL {
        if let urlString = self.baseURLString, let url = URL(string: urlString) {
            return url
        } else {
            fatalError()
        }
    }

    func completeCharge(_ result: STPPaymentResult, amount: Int, completion: @escaping STPErrorBlock) {
        let url = self.baseURL.appendingPathComponent("charge")
        Alamofire.request(url, method: .post, parameters: [
            "source": result.source.stripeID,
            "amount": amount
            ])
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
        }
    }
    
    @objc func retrieveCustomer(_ completion: @escaping STPCustomerCompletionBlock) {
        let url = self.baseURL.appendingPathComponent("customer")
        Alamofire.request(url)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                switch response.result {
                case .success(let result):
                    if let customer = STPCustomer.decodedObject(fromAPIResponse: result as? [String: AnyObject]) {
                        completion(customer, nil)
                    } else {
                        completion(nil, NSError.customerDecodingError)
                    }
                case .failure(let error):
                    completion(nil, error)
                }
        }
    }
    
    @objc func selectDefaultCustomerSource(_ source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        let url = self.baseURL.appendingPathComponent("customer/default_source")
        Alamofire.request(url, method: .post, parameters: [
            "source": source.stripeID,
            ])
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
        }
    }
    
    @objc func attachSource(toCustomer source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        let url = self.baseURL.appendingPathComponent("customer/sources")
        Alamofire.request(url, method: .post, parameters: [
            "source": source.stripeID,
            ])
            .validate(statusCode: 200..<300)
            .responseString { response in
                switch response.result {
                case .success:
                    completion(nil)
                case .failure(let error):
                    completion(error)
                }
        }
    }
}

extension NSError {
    static var customerDecodingError: NSError {
        return NSError(domain: StripeDomain, code: 50, userInfo: [
            NSLocalizedDescriptionKey: "Failed to decode the Stripe customer. Have you modified the example backend?"
            ])
    }
}
