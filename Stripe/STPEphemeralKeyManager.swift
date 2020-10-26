//
//  STPEphemeralKeyManager.swift
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit

typealias STPEphemeralKeyCompletionBlock = (STPEphemeralKey?, Error?) -> Void
class STPEphemeralKeyManager: NSObject {
  /// If the current ephemeral key expires in less than this time interval, a call
  /// to `getOrCreateKey` will request a new key from the manager's key provider.
  /// The maximum allowed value is one hour – higher values will be clamped.

  private var _expirationInterval: TimeInterval = 0.0
  var expirationInterval: TimeInterval {
    get {
      _expirationInterval
    }
    set(expirationInterval) {
      _expirationInterval = TimeInterval(min(expirationInterval, 60 * 60))
    }
  }
  /// If this value is YES, the manager will eagerly refresh its key on app foregrounding.
  private(set) var performsEagerFetching = false

  /// Initializes a new `STPEphemeralKeyManager` with the specified key provider.
  /// - Parameters:
  ///   - keyProvider:               The key provider the manager will use.
  ///   - apiVersion:                The Stripe API version the manager will use.
  ///   - performsEagerFetching:     If the manager should eagerly refresh its key on app foregrounding.
  /// - Returns: the newly-initiated `STPEphemeralKeyManager`.
  @objc init(
    keyProvider: Any?,
    apiVersion: String,
    performsEagerFetching: Bool
  ) {
    super.init()
    assert(
      keyProvider is STPCustomerEphemeralKeyProvider
        || keyProvider is STPIssuingCardEphemeralKeyProvider,
      "Your STPEphemeralKeyProvider must either implement `STPCustomerEphemeralKeyProvider` or `STPIssuingCardEphemeralKeyProvider`."
    )
    expirationInterval = DefaultExpirationInterval
    self.keyProvider = keyProvider
    self.apiVersion = apiVersion
    self.performsEagerFetching = performsEagerFetching
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWillForegroundNotification),
      name: UIApplication.willEnterForegroundNotification,
      object: nil)
  }

  /// If the retriever's stored ephemeral key has not expired, it will be
  /// returned immediately to the given callback. If the stored key is expiring, a
  /// new key will be requested from the key provider, and returned to the callback.
  /// If the retriever is unable to provide an unexpired key, an error will be returned.
  /// - Parameter completion: The callback to be run with the returned key, or an error.
  @objc dynamic func getOrCreateKey(_ completion: @escaping STPEphemeralKeyCompletionBlock) {
    if currentKeyIsUnexpired() {
      completion(ephemeralKey, nil)
    } else {
      if let createKeyPromise = createKeyPromise {
        // coalesce repeated calls into one request
        createKeyPromise.onSuccess({ key in
          completion(key, nil)
        }).onFailure({ error in
          completion(nil, error)
        })
      } else {
        createKeyPromise = STPPromise<STPEphemeralKey>.init().onSuccess({ key in
          self.ephemeralKey = key
          completion(key, nil)
        }).onFailure({ error in
          completion(nil, error)
        })
        _createKey()
      }
    }
  }

  @objc internal var ephemeralKey: STPEphemeralKey?
  private var apiVersion: String?
  private var keyProvider: Any?
  @objc internal var lastEagerKeyRefresh: Date?
  private var createKeyPromise: STPPromise<STPEphemeralKey>?

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: UIApplication.willEnterForegroundNotification,
      object: nil)
  }

  func currentKeyIsUnexpired() -> Bool {
    return ephemeralKey != nil
      && (ephemeralKey?.expires.timeIntervalSinceNow ?? 0.0) > expirationInterval
  }

  func shouldPerformEagerRefresh() -> Bool {
    return performsEagerFetching
      && (lastEagerKeyRefresh == nil
        || (lastEagerKeyRefresh?.timeIntervalSinceNow ?? 0.0) > MinEagerRefreshInterval)
  }

  @objc func handleWillForegroundNotification() {
    // To make sure we don't end up hitting the ephemeral keys endpoint on every
    // foreground (e.g. if there's an issue decoding the ephemeral key), throttle
    // eager refreshes to once per hour.
    if !currentKeyIsUnexpired() && shouldPerformEagerRefresh() {
      lastEagerKeyRefresh = Date()
      getOrCreateKey({ _, _ in
        // getOrCreateKey sets the self.ephemeralKey. Nothing left to do for us here
      })
    }
  }

  func _createKey() {
    let jsonCompletion =
      { (jsonResponse: [AnyHashable: Any]?, error: Error?) in
        let key = STPEphemeralKey.decodedObject(fromAPIResponse: jsonResponse)
        if let key = key {
          self.createKeyPromise?.succeed(key)
        } else {
          // the API request failed
          if let error = error {
            self.createKeyPromise?.fail(error)
          } else {
            // the ephemeral key could not be decoded
            self.createKeyPromise?.fail(NSError.stp_ephemeralKeyDecodingError())
            if self.keyProvider is STPCustomerEphemeralKeyProvider {
              assert(
                false,
                "Could not parse the ephemeral key response following protocol STPCustomerEphemeralKeyProvider. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api"
              )
            } else if self.keyProvider is STPIssuingCardEphemeralKeyProvider {
              assert(
                false,
                "Could not parse the ephemeral key response following protocol STPIssuingCardEphemeralKeyProvider. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api"
              )
            }
            assert(
              false,
              "Could not parse the ephemeral key response. Make sure your backend is sending the unmodified JSON of the ephemeral key to your app. For more info, see https://stripe.com/docs/mobile/ios/standard#prepare-your-api"
            )
          }
        }
        self.createKeyPromise = nil
      } as STPJSONResponseCompletionBlock

    if keyProvider is STPCustomerEphemeralKeyProvider {
      weak var provider = keyProvider as? STPCustomerEphemeralKeyProvider
      provider?.createCustomerKey(withAPIVersion: apiVersion ?? "", completion: jsonCompletion)
    } else if keyProvider is STPIssuingCardEphemeralKeyProvider {
      weak var provider = keyProvider as? STPIssuingCardEphemeralKeyProvider
      provider?.createIssuingCardKey(withAPIVersion: apiVersion ?? "", completion: jsonCompletion)
    }
  }
}

private let DefaultExpirationInterval: TimeInterval = 60
private let MinEagerRefreshInterval: TimeInterval = 60 * 60
