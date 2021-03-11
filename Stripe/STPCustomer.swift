//
//  STPCustomer.swift
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

/// An `STPCustomer` represents a deserialized Customer object from the Stripe API.
/// You shouldn't need to instantiate an `STPCustomer` – you should instead use
/// `STPCustomerContext` to manage retrieving and updating a customer.
public class STPCustomer: NSObject {

    /// The Stripe ID of the customer, e.g. `cus_1234`
    @objc public let stripeID: String

    /// The default source used to charge the customer.
    @objc public private(set) var defaultSource: STPSourceProtocol?

    /// The available payment sources the customer has (this may be an empty array).
    @objc public private(set) var sources: [STPSourceProtocol]

    /// The customer's shipping address.
    @objc public var shippingAddress: STPAddress?

    @objc public let allResponseFields: [AnyHashable: Any]

    /// Initialize a customer object with the provided values.
    /// - Parameters:
    ///   - stripeID:      The ID of the customer, e.g. `cus_abc`
    ///   - defaultSource: The default source of the customer, such as an `STPCard` object. Can be nil.
    ///   - sources:       All of the customer's payment sources. This might be an empty array.
    /// - Returns: an instance of STPCustomer
    @objc
    public convenience init(
        stripeID: String,
        defaultSource: STPSourceProtocol?,
        sources: [STPSourceProtocol]
    ) {
        self.init(
            stripeID: stripeID,
            defaultSource: defaultSource,
            sources: sources,
            shippingAddress: nil,
            allResponseFields: [:])
    }

    internal init(
        stripeID: String,
        defaultSource: STPSourceProtocol?,
        sources: [STPSourceProtocol],
        shippingAddress: STPAddress?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.stripeID = stripeID
        self.defaultSource = defaultSource
        self.sources = sources
        self.shippingAddress = shippingAddress
        self.allResponseFields = allResponseFields
        super.init()
    }

    convenience override init() {
        self.init(
            stripeID: "",
            defaultSource: nil,
            sources: [],
            shippingAddress: nil,
            allResponseFields: [:])
    }

    // MARK: - Description
    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPCustomer.self), self),
            // Identifier
            "stripeID = \(stripeID)",
            // Sources
            "defaultSource = \(String(describing: defaultSource))",
            "sources = \(sources)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }

    /**
     Replaces the customer's `sources` and `defaultSource` based on whether or not
     they should include Apple Pay sources. More details on documentation for
     `STPCustomerContext includeApplePaySources`

     @param filteringApplePay      If YES, Apple Pay sources will be ignored
     */
    @objc(updateSourcesFilteringApplePay:)
    public func updateSources(filteringApplePay: Bool) {
        let (defaultSource, sources) = STPCustomer.sources(
            from: allResponseFields, filterApplePay: filteringApplePay)
        self.defaultSource = defaultSource
        self.sources = sources
    }
}

extension STPCustomer: STPAPIResponseDecodable {
    @objc
    public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let stripeID = dict["id"] as? String
        else {
            return nil
        }

        let shippingAddress: STPAddress?

        if let shippingDict = dict["shipping"] as? [AnyHashable: Any],
            let addressDict = shippingDict["address"] as? [AnyHashable: Any],
            let shipping = STPAddress.decodedObject(fromAPIResponse: addressDict)
        {
            shipping.name = shippingDict["name"] as? String
            shipping.phone = shippingDict["phone"] as? String
            shippingAddress = shipping
        } else {
            shippingAddress = nil
        }
        let (defaultSource, sources) = STPCustomer.sources(from: dict, filterApplePay: true)

        return STPCustomer(
            stripeID: stripeID,
            defaultSource: defaultSource,
            sources: sources,
            shippingAddress: shippingAddress,
            allResponseFields: dict) as? Self

    }

    private class func sources(from response: [AnyHashable: Any], filterApplePay: Bool) -> (
        default: STPSourceProtocol?, sources: [STPSourceProtocol]
    ) {

        guard let sourcesDict = response["sources"] as? [AnyHashable: Any],
            let data = sourcesDict["data"] as? [[AnyHashable: Any]]
        else {
            return (nil, [])
        }

        var defaultSource: STPSourceProtocol?
        let defaultSourceId = response["default_source"] as? String
        var sources: [STPSourceProtocol] = []

        for contents in data {
            if let object = contents["object"] as? String {
                if object == "card" {
                    if let card = STPCard.decodedObject(fromAPIResponse: contents),
                        !filterApplePay || !card.isApplePayCard
                    {

                        sources.append(card)

                        if let defaultSourceId = defaultSourceId,
                            card.stripeID == defaultSourceId
                        {
                            defaultSource = card
                        }
                    }
                } else if object == "source" {
                    if let source = STPSource.decodedObject(fromAPIResponse: contents),
                        !filterApplePay || !(source.cardDetails?.isApplePayCard ?? false)
                    {
                        sources.append(source)

                        if let defaultSourceId = defaultSourceId,
                            source.stripeID == defaultSourceId
                        {
                            defaultSource = source
                        }
                    }
                }
            } else {
                continue
            }

        }
        return (defaultSource, sources)
    }
}

/// Use `STPCustomerDeserializer` to convert a response from the Stripe API into an `STPCustomer` object. `STPCustomerDeserializer` expects the JSON response to be in the exact same format as the Stripe API.
public class STPCustomerDeserializer: NSObject {

    /// If a customer was successfully parsed from the response, it will be set here. Otherwise, this value wil be nil (and the `error` property will explain what went wrong).
    @objc public let customer: STPCustomer?
    /// If the deserializer failed to parse a customer, this property will explain why (and the `customer` property will be nil).
    @objc public let error: Error?

    /// Initialize a customer deserializer. The `data`, `urlResponse`, and `error`
    /// parameters are intended to be passed from an `NSURLSessionDataTask` callback.
    /// After it has been initialized, you can inspect the `error` and `customer`
    /// properties to see if the deserialization was successful. If `error` is nil,
    /// `customer` will be non-nil (and vice versa).
    /// - Parameters:
    ///   - data:        An `NSData` object representing encoded JSON for a Customer object
    ///   - urlResponse: The URL response obtained from the `NSURLSessionTask`
    ///   - error:       Any error that occurred from the URL session task (if this
    /// is non-nil, the `error` property will be set to this value after initialization).
    @objc
    public convenience init(
        data: Data?,
        urlResponse: URLResponse?,
        error: Error?
    ) {
        if let error = error {
            self.init(customer: nil, error: error)
        } else if let data = data {
            var json: Any?
            do {
                json = try JSONSerialization.jsonObject(with: data, options: [])
            } catch let jsonError {
                self.init(customer: nil, error: jsonError)
                return
            }
            self.init(jsonResponse: json)
        } else {
            self.init(customer: nil, error: NSError.stp_genericFailedToParseResponseError())
        }
    }

    /// Initializes a customer deserializer with a JSON dictionary. This JSON should be
    /// in the exact same format as what the Stripe API returns. If it's successfully
    /// parsed, the `customer` parameter will be present after initialization;
    /// otherwise `error` will be present.
    /// - Parameter json: a JSON dictionary.
    @objc
    public convenience init(jsonResponse json: Any?) {
        if let customer = STPCustomer.decodedObject(fromAPIResponse: json as? [AnyHashable: Any]) {
            self.init(customer: customer, error: nil)
        } else {
            self.init(customer: nil, error: NSError.stp_genericFailedToParseResponseError())
        }
    }

    private init(customer: STPCustomer?, error: Error?) {
        self.customer = customer
        self.error = error
        super.init()
    }
}
