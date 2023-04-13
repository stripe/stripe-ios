//
//  STPAPIClient+CustomerContext.swift
//  StripePaymentsUI
//
//  Created by David Estes on 3/13/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

extension STPAPIClient {

    /// Update a customer with parameters
    /// - seealso: https://stripe.com/docs/api#update_customer
    func updateCustomer(
        withParameters parameters: [String: Any],
        using ephemeralKey: _stpspmsbeta_STPEphemeralKey,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        guard let customerID = ephemeralKey.customerID else {
            completion(nil, NSError.stp_ephemeralKeyDecodingError())
            return
        }
        let endpoint = "\(APIEndpointCustomers)/\(customerID)"
        APIRequest<STPCustomer>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(usingEphemeralKey: ephemeralKey),
            parameters: parameters
        ) { object, _, error in
            completion(object, error)
        }
    }

    /// Attach a Payment Method to a customer
    /// - seealso: https://stripe.com/docs/api/payment_methods/attach
    func attachPaymentMethod(
        _ paymentMethodID: String,
        toCustomerUsing ephemeralKey: _stpspmsbeta_STPEphemeralKey,
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
            additionalHeaders: authorizationHeader(usingEphemeralKey: ephemeralKey),
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
        fromCustomerUsing ephemeralKey: _stpspmsbeta_STPEphemeralKey,
        completion: @escaping STPErrorBlock
    ) {
        let endpoint = "\(APIEndpointPaymentMethods)/\(paymentMethodID)/detach"
        APIRequest<STPPaymentMethod>.post(
            with: self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(usingEphemeralKey: ephemeralKey),
            parameters: [:]
        ) { _, _, error in
            completion(error)
        }
    }

    /// Retrieves a list of Payment Methods attached to a customer.
    /// @note This only fetches card type Payment Methods
    func listPaymentMethodsForCustomer(
        using ephemeralKey: _stpspmsbeta_STPEphemeralKey,
        completion: @escaping STPPaymentMethodsCompletionBlock
    ) {
        guard let customerID = ephemeralKey.customerID else {
            completion(nil, NSError.stp_ephemeralKeyDecodingError())
            return
        }
        let header = authorizationHeader(usingEphemeralKey: ephemeralKey)
        let params: [String: Any] = [
            "customer": customerID,
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
        using ephemeralKey: _stpspmsbeta_STPEphemeralKey,
        completion: @escaping STPCustomerCompletionBlock
    ) {
        guard let customerID = ephemeralKey.customerID else {
            completion(nil, NSError.stp_ephemeralKeyDecodingError())
            return
        }
        let endpoint = "\(APIEndpointCustomers)/\(customerID)"
        APIRequest<STPCustomer>.getWith(
            self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(usingEphemeralKey: ephemeralKey),
            parameters: [:]
        ) { object, _, error in
            completion(object, error)
        }
    }

    // MARK: Helpers

    /// A helper method that returns the Authorization header to use for API requests. If ephemeralKey is nil, uses self.publishableKey instead.
    @_spi(STP) public func authorizationHeader(usingEphemeralKey ephemeralKey: _stpspmsbeta_STPEphemeralKey? = nil) -> [String: String] {
        return authorizationHeader(using: ephemeralKey?.secret)
    }
}
