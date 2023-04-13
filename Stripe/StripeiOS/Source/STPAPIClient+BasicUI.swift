//
//  STPAPIClient+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// A client for making connections to the Stripe API.
extension STPAPIClient {
    /// Initializes an API client with the given configuration.
    /// - Parameter configuration: The configuration to use.
    /// - Returns: An instance of STPAPIClient.
    @available(
        *,
        deprecated,
        message:
            "This initializer previously configured publishableKey and stripeAccount via the STPPaymentConfiguration instance. This behavior is deprecated; set the STPAPIClient configuration, publishableKey, and stripeAccount properties directly on the STPAPIClient instead."
    )
    public convenience init(
        configuration: STPPaymentConfiguration
    ) {
        // For legacy reasons, we'll support this initializer and use the deprecated configuration.{publishableKey, stripeAccount} properties
        self.init()
        publishableKey = configuration.publishableKey
        stripeAccount = configuration.stripeAccount
    }
}

extension STPAPIClient {
    /// The client's configuration.
    /// Defaults to `STPPaymentConfiguration.shared`.
    @objc public var configuration: STPPaymentConfiguration {
        get {
            if let config = _stored_configuration as? STPPaymentConfiguration {
                return config
            } else {
                return .shared
            }
        }
        set {
            _stored_configuration = newValue
        }
    }

    /// Update a customer with parameters
    /// - seealso: https://stripe.com/docs/api#update_customer
    func updateCustomer(
        withParameters parameters: [String: Any],
        using ephemeralKey: STPEphemeralKey,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        let endpoint = "\(APIEndpointCustomers)/\(ephemeralKey.customerID ?? "")"
        APIRequest<STPCustomer>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: parameters
        ) { object, _, error in
            completion(object, error)
        }
    }

    /// Attach a Payment Method to a customer
    /// - seealso: https://stripe.com/docs/api/payment_methods/attach
    func attachPaymentMethod(
        _ paymentMethodID: String,
        toCustomerUsing ephemeralKey: STPEphemeralKey,
        completion: @escaping STPErrorBlock
    ) {
        guard let customerID = ephemeralKey.customerID else {
            assertionFailure()
            completion(nil)
            return
        }
        let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/attach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: [
                "customer": customerID
            ]
        ) { _, _, error in
            completion(error)
        }
    }

    /// Detach a Payment Method from a customer
    /// - seealso: https://stripe.com/docs/api/payment_methods/detach
    func detachPaymentMethod(
        _ paymentMethodID: String,
        fromCustomerUsing ephemeralKey: STPEphemeralKey,
        completion: @escaping STPErrorBlock
    ) {
        let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/detach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: [:]
        ) { _, _, error in
            completion(error)
        }
    }

    /// Retrieves a list of Payment Methods attached to a customer.
    /// @note This only fetches card type Payment Methods
    func listPaymentMethodsForCustomer(
        using ephemeralKey: STPEphemeralKey,
        completion: @escaping STPPaymentMethodsCompletionBlock
    ) {
        let header = authorizationHeader(using: ephemeralKey)
        let params: [String: Any] = [
            "customer": ephemeralKey.customerID ?? "",
            "type": "card",
        ]
        APIRequest<STPPaymentMethodListDeserializer>.getWith(
            self,
            endpoint: APIEndpointPaymentMethods,
            additionalHeaders: header,
            parameters: params as [String: Any]
        ) { deserializer, _, error in
            if let error = error {
                completion(nil, error)
            } else if let paymentMethods = deserializer?.paymentMethods {
                completion(paymentMethods, nil)
            }
        }
    }

    /// Retrieve a customer
    /// - seealso: https://stripe.com/docs/api#retrieve_customer
    func retrieveCustomer(
        using ephemeralKey: STPEphemeralKey,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        let endpoint = "\(APIEndpointCustomers)/\(ephemeralKey.customerID ?? "")"
        APIRequest<STPCustomer>.getWith(
            self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: [:]
        ) { object, _, error in
            completion(object, error)
        }
    }

    // MARK: FPX
    /// Retrieves the online status of the FPX banks from the Stripe API.
    /// - Parameter completion:  The callback to run with the returned FPX bank list, or an error.
    func retrieveFPXBankStatus(
        withCompletion completion: @escaping STPFPXBankStatusCompletionBlock
    ) {
        APIRequest<STPFPXBankStatusResponse>.getWith(
            self,
            endpoint: APIEndpointFPXStatus,
            parameters: [
                "account_holder_type": "individual"
            ]
        ) { statusResponse, _, error in
            completion(statusResponse, error)
        }
    }

    // MARK: Helpers

    /// A helper method that returns the Authorization header to use for API requests. If ephemeralKey is nil, uses self.publishableKey instead.
    func authorizationHeader(using ephemeralKey: STPEphemeralKey? = nil) -> [String: String] {
        return authorizationHeader(using: ephemeralKey?.secret)
    }
}

private let APIEndpointFPXStatus = "fpx/bank_statuses"
