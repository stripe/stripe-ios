//
//  STPCustomerContext.swift
//  Stripe
//
//  Created by Ben Guo on 5/2/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation

/// An `STPCustomerContext` retrieves and updates a Stripe customer and their attached
/// payment methods using an ephemeral key, a short-lived API key scoped to a specific
/// customer object. If your current user logs out of your app and a new user logs in,
/// be sure to either create a new instance of `STPCustomerContext` or clear the current
/// instance's cache. On your backend, be sure to create and return a
/// new ephemeral key for the Customer object associated with the new user.
open class STPCustomerContext: NSObject, STPBackendAPIAdapter {
  /// Initializes a new `STPCustomerContext` with the specified key provider.
  /// Upon initialization, a CustomerContext will fetch a new ephemeral key from
  /// your backend and use it to prefetch the customer object specified in the key.
  /// Subsequent customer and payment method retrievals (e.g. by `STPPaymentContext`)
  /// will return the prefetched customer / attached payment methods immediately if
  /// its age does not exceed 60 seconds.
  /// - Parameter keyProvider:   The key provider the customer context will use.
  /// - Returns: the newly-instantiated customer context.
  @objc(initWithKeyProvider:)
  public convenience init(keyProvider: STPCustomerEphemeralKeyProvider) {
    self.init(keyProvider: keyProvider, apiClient: STPAPIClient.shared)
  }

  /// Initializes a new `STPCustomerContext` with the specified key provider.
  /// Upon initialization, a CustomerContext will fetch a new ephemeral key from
  /// your backend and use it to prefetch the customer object specified in the key.
  /// Subsequent customer and payment method retrievals (e.g. by `STPPaymentContext`)
  /// will return the prefetched customer / attached payment methods immediately if
  /// its age does not exceed 60 seconds.
  /// - Parameters:
  ///   - keyProvider:   The key provider the customer context will use.
  ///   - apiClient:       The API Client to use to make requests.
  /// - Returns: the newly-instantiated customer context.
  @objc(initWithKeyProvider:apiClient:)
  public convenience init(
    keyProvider: STPCustomerEphemeralKeyProvider?, apiClient: STPAPIClient
  ) {
    let keyManager = STPEphemeralKeyManager(
      keyProvider: keyProvider,
      apiVersion: STPAPIClient.apiVersion,
      performsEagerFetching: true)
    self.init(keyManager: keyManager, apiClient: apiClient)
  }

  /// `STPCustomerContext` will cache its customer object and associated payment methods
  /// for up to 60 seconds. If your current user logs out of your app and a new user logs
  /// in, be sure to either call this method or create a new instance of `STPCustomerContext`.
  /// On your backend, be sure to create and return a new ephemeral key for the
  /// customer object associated with the new user.
  @objc
  public func clearCache() {
    clearCachedCustomer()
    clearCachedPaymentMethods()
  }

  private var _includeApplePayPaymentMethods = false
  /// By default, `STPCustomerContext` will filter Apple Pay when it retrieves
  /// Payment Methods. Apple Pay payment methods should generally not be re-used and
  /// shouldn't be offered to customers as a new payment method (Apple Pay payment
  /// methods may only be re-used for subscriptions).
  /// If you are using `STPCustomerContext` to back your own UI and would like to
  /// disable Apple Pay filtering, set this property to YES.
  /// Note: If you are using `STPPaymentContext`, you should not change this property.
  @objc public var includeApplePayPaymentMethods: Bool {
    get {
      _includeApplePayPaymentMethods
    }
    set(includeApplePayMethods) {
      _includeApplePayPaymentMethods = includeApplePayMethods
      customer?.updateSources(filteringApplePay: !includeApplePayMethods)
    }
  }

  private var _customer: STPCustomer?
  private var customer: STPCustomer? {
    get {
      _customer
    }
    set(customer) {
      _customer = customer
      customerRetrievedDate = (customer) != nil ? Date() : nil
    }
  }
  @objc internal var customerRetrievedDate: Date?

  private var _paymentMethods: [STPPaymentMethod]?
  private var paymentMethods: [STPPaymentMethod]? {
    get {
      if !includeApplePayPaymentMethods {
        var paymentMethodsExcludingApplePay: [STPPaymentMethod]? = []
        for paymentMethod in _paymentMethods ?? [] {
          let isApplePay =
            paymentMethod.type == .card && paymentMethod.card?.wallet?.type == .applePay
          if !isApplePay {
            paymentMethodsExcludingApplePay?.append(paymentMethod)
          }
        }
        return paymentMethodsExcludingApplePay ?? []
      } else {
        return _paymentMethods ?? []
      }
    }
    set(paymentMethods) {
      _paymentMethods = paymentMethods
      paymentMethodsRetrievedDate = paymentMethods != nil ? Date() : nil
    }
  }
  @objc internal var paymentMethodsRetrievedDate: Date?
  private var keyManager: STPEphemeralKeyManager
  private var apiClient: STPAPIClient

  @objc init(keyManager: STPEphemeralKeyManager, apiClient: STPAPIClient) {
    STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPCustomerContext.self)
    self.keyManager = keyManager
    self.apiClient = apiClient
    _includeApplePayPaymentMethods = false
    super.init()
    retrieveCustomer(nil)
    listPaymentMethodsForCustomer(completion: nil)
  }

  func clearCachedCustomer() {
    customer = nil
  }

  func clearCachedPaymentMethods() {
    paymentMethods = nil
  }

  func shouldUseCachedCustomer() -> Bool {
    if customer == nil || customerRetrievedDate == nil {
      return false
    }
    let now = Date()
    if let customerRetrievedDate = customerRetrievedDate {
      return now.timeIntervalSince(customerRetrievedDate) < CachedCustomerMaxAge
    }
    return false
  }

  func shouldUseCachedPaymentMethods() -> Bool {
    if paymentMethods == nil || paymentMethodsRetrievedDate == nil {
      return false
    }
    let now = Date()
    if let paymentMethodsRetrievedDate = paymentMethodsRetrievedDate {
      return now.timeIntervalSince(paymentMethodsRetrievedDate) < CachedCustomerMaxAge
    }
    return false
  }

  // MARK: - STPBackendAPIAdapter
  @objc
  public func retrieveCustomer(_ completion: STPCustomerCompletionBlock? = nil) {
    if shouldUseCachedCustomer() {
      if let completion = completion {
        stpDispatchToMainThreadIfNecessary({
          completion(self.customer, nil)
        })
      }
      return
    }
    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(nil, retrieveKeyError)
          })
        }
        return
      }
      self.apiClient.retrieveCustomer(using: ephemeralKey) { customer, error in
        if let customer = customer {
          customer.updateSources(filteringApplePay: !self.includeApplePayPaymentMethods)
          self.customer = customer
        }
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(self.customer, error)
          })
        }
      }
    })
  }

  @objc
  public func updateCustomer(
    withShippingAddress shipping: STPAddress, completion: STPErrorBlock?
  ) {
    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(retrieveKeyError)
          })
        }
        return
      }
      var params: [String: Any] = [:]
      params["shipping"] = STPAddress.shippingInfoForCharge(
        with: shipping,
        shippingMethod: nil)
      self.apiClient.updateCustomer(
        withParameters: params,
        using: ephemeralKey
      ) { customer, error in
        if let customer = customer {
          customer.updateSources(filteringApplePay: !self.includeApplePayPaymentMethods)
          self.customer = customer
        }
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(error)
          })
        }
      }
    })
  }

  @objc
  public func attachPaymentMethod(
    toCustomer paymentMethod: STPPaymentMethod, completion: STPErrorBlock?
  ) {
    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(retrieveKeyError)
          })
        }
        return
      }

      self.apiClient.attachPaymentMethod(
        paymentMethod.stripeId ?? "",
        toCustomerUsing: ephemeralKey
      ) { error in
        self.clearCachedPaymentMethods()
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(error)
          })
        }
      }
    })
  }

  @objc
  public func detachPaymentMethod(
    fromCustomer paymentMethod: STPPaymentMethod, completion: STPErrorBlock?
  ) {
    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(retrieveKeyError)
          })
        }
        return
      }

      self.apiClient.detachPaymentMethod(
        paymentMethod.stripeId ?? "",
        fromCustomerUsing: ephemeralKey
      ) { error in
        self.clearCachedPaymentMethods()
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(error)
          })
        }
      }
    })

  }

  @objc
  public func listPaymentMethodsForCustomer(completion: STPPaymentMethodsCompletionBlock? = nil) {
    if shouldUseCachedPaymentMethods() {
      if let completion = completion {
        stpDispatchToMainThreadIfNecessary({
          completion(self.paymentMethods, nil)
        })
      }
      return
    }

    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(nil, retrieveKeyError)
          })
        }
        return
      }

      self.apiClient.listPaymentMethodsForCustomer(using: ephemeralKey) { paymentMethods, error in
        if paymentMethods != nil {
          self.paymentMethods = paymentMethods
        }
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(self.paymentMethods, error)
          })
        }
      }
    })
  }

  func saveLastSelectedPaymentMethodID(
    forCustomer paymentMethodID: String?, completion: STPErrorBlock?
  ) {
    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        if let completion = completion {
          stpDispatchToMainThreadIfNecessary({
            completion(retrieveKeyError)
          })
        }
        return
      }

      var customerToDefaultPaymentMethodID =
        (UserDefaults.standard.dictionary(forKey: kLastSelectedPaymentMethodDefaultsKey))
        as? [String: String] ?? [:]
      if let customerID = ephemeralKey.customerID {
        customerToDefaultPaymentMethodID[customerID] = paymentMethodID
        UserDefaults.standard.set(
          customerToDefaultPaymentMethodID, forKey: kLastSelectedPaymentMethodDefaultsKey)
      }

      if let completion = completion {
        stpDispatchToMainThreadIfNecessary({
          completion(nil)
        })
      }
    })
  }

  func retrieveLastSelectedPaymentMethodIDForCustomer(
    completion: @escaping (String?, Error?) -> Void
  ) {
    keyManager.getOrCreateKey({ ephemeralKey, retrieveKeyError in
      guard let ephemeralKey = ephemeralKey, retrieveKeyError == nil else {
        stpDispatchToMainThreadIfNecessary({
          completion(nil, retrieveKeyError)
        })
        return
      }

      let customerToDefaultPaymentMethodID =
        (UserDefaults.standard.dictionary(forKey: kLastSelectedPaymentMethodDefaultsKey))
        as? [String: String] ?? [:]
      stpDispatchToMainThreadIfNecessary({
        completion(customerToDefaultPaymentMethodID[ephemeralKey.customerID ?? ""], nil)
      })
    })
  }
}

/// Stores the key we use in NSUserDefaults to save a dictionary of Customer id to their last selected payment method ID
private let kLastSelectedPaymentMethodDefaultsKey =
  "com.stripe.lib:STPStripeCustomerToLastSelectedPaymentMethodKey"
private let CachedCustomerMaxAge: TimeInterval = 60
