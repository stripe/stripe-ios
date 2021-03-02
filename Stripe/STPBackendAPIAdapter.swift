//
//  STPBackendAPIAdapter.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

/// A "bridge" from our pre-built UI (`STPPaymentContext`, `STPPaymentOptionsViewController`)
/// to your backend to fetch Customer-related information needed to power those views.
/// Typically, you will not need to implement this protocol yourself. You
/// should instead use `STPCustomerContext`, which implements <STPBackendAPIAdapter>
/// and manages retrieving and updating a Stripe customer for you.
/// - seealso: STPCustomerContext.h
/// If you would prefer retrieving and updating your Stripe customer object via
/// your own backend instead of using `STPCustomerContext`, you should make your
/// application's API client conform to this interface.
@objc public protocol STPBackendAPIAdapter: NSObjectProtocol {
    /// Retrieve the customer to be displayed inside a payment context.
    /// If you are not using STPCustomerContext:
    /// On your backend, retrieve the Stripe customer associated with your currently
    /// logged-in user ( https://stripe.com/docs/api#retrieve_customer ), and return
    /// the raw JSON response from the Stripe API. Back in your iOS app, after you've
    /// called this API, deserialize your API response into an `STPCustomer` object
    /// (you can use the `STPCustomerDeserializer` class to do this).
    /// - seealso: STPCard
    /// - Parameter completion: call this callback when you're done fetching and parsing the above information from your backend. For example, `completion(customer, nil)` (if your call succeeds) or `completion(nil, error)` if an error is returned.
    func retrieveCustomer(_ completion: STPCustomerCompletionBlock?)
    /// Retrieves a list of Payment Methods attached to a customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// Call the list method ( https://stripe.com/docs/api/payment_methods/lists )
    /// with the Stripe customer. If this API call succeeds, call `completion(paymentMethods)`
    /// with the list of PaymentMethods. Otherwise, call `completion(error)` with the error
    /// that occurred.
    /// - Parameter completion:  Call this callback with the list of Payment Methods attached to the
    /// customer.  For example, `completion(paymentMethods)` (if your call succeeds) or
    /// `completion(error)` if an error is returned.
    func listPaymentMethodsForCustomer(completion: STPPaymentMethodsCompletionBlock?)
    /// Adds a Payment Method to a customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// On your backend, retrieve the Stripe customer associated with your logged-in user.
    /// Then, call the Attach method on the Payment Method with that customer's ID
    /// ( https://stripe.com/docs/api/payment_methods/attach ). If this API call succeeds,
    /// call `completion(nil)`. Otherwise, call `completion(error)` with the error that
    /// occurred.
    /// - Parameters:
    ///   - paymentMethod:   A valid Payment Method
    ///   - completion:      Call this callback when you're done adding the payment method
    /// to the customer on your backend. For example, `completion(nil)` (if your call succeeds)
    /// or `completion(error)` if an error is returned.
    func attachPaymentMethod(toCustomer paymentMethod: STPPaymentMethod, completion: STPErrorBlock?)

    /// Deletes the given Payment Method from the customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// Call the Detach method ( https://stripe.com/docs/api/payment_methods/detach )
    /// on the Payment Method. If this API call succeeds, call `completion(nil)`.
    /// Otherwise, call `completion(error)` with the error that occurred.
    /// - Parameters:
    ///   - paymentMethod:   The Payment Method to delete from the customer
    ///   - completion:      Call this callback when you're done deleting the Payment Method
    /// from the customer on your backend. For example, `completion(nil)` (if your call
    /// succeeds) or `completion(error)` if an error is returned.
    @objc optional func detachPaymentMethod(
        fromCustomer paymentMethod: STPPaymentMethod, completion: STPErrorBlock?)
    /// Sets the given shipping address on the customer.
    /// If you are implementing your own <STPBackendAPIAdapter>:
    /// On your backend, retrieve the Stripe customer associated with your logged-in user.
    /// Then, call the Customer Update method ( https://stripe.com/docs/api#update_customer )
    /// specifying shipping to be the given shipping address. If this API call succeeds,
    /// call `completion(nil)`. Otherwise, call `completion(error)` with the error that occurred.
    /// - Parameters:
    ///   - shipping:   The shipping address to set on the customer
    ///   - completion: call this callback when you're done updating the customer on
    /// your backend. For example, `completion(nil)` (if your call succeeds) or
    /// `completion(error)` if an error is returned.
    /// - seealso: https://stripe.com/docs/api#update_customer
    @objc optional func updateCustomer(
        withShippingAddress shipping: STPAddress, completion: STPErrorBlock?)
}
