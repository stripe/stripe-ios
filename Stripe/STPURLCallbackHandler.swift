//
//  STPURLCallbackHandler.swift
//  Stripe
//
//  Created by Brian Dorfman on 10/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@objc protocol STPURLCallbackListener: NSObjectProtocol {
  func handleURLCallback(_ url: URL) -> Bool
}

class STPURLCallbackHandler: NSObject {
  static var sharedHandler: STPURLCallbackHandler = STPURLCallbackHandler()

  @objc class func shared() -> STPURLCallbackHandler {
    return sharedHandler
  }

  @objc @discardableResult func handleURLCallback(_ url: URL) -> Bool {
    let components = NSURLComponents(
      url: url,
      resolvingAgainstBaseURL: false)

    var resultsOrred = false

    for callback in callbacks {
      if let components = components {
        if callback.urlComponents?.stp_matchesURLComponents(components) ?? false {
          resultsOrred = resultsOrred || (callback.listener?.handleURLCallback(url) ?? false)
        }
      }
    }

    return resultsOrred
  }

  @objc(registerListener:forURL:) func register(
    _ listener: STPURLCallbackListener?,
    for url: URL
  ) {

    let callback = STPURLCallback()
    callback.listener = listener
    callback.urlComponents = NSURLComponents(
      url: url,
      resolvingAgainstBaseURL: false)

    if callback.listener != nil && callback.urlComponents != nil {
      var callbacksCopy = callbacks
      callbacksCopy.append(callback)
      callbacks = callbacksCopy
    }
  }

  @objc func unregisterListener(_ listener: STPURLCallbackListener) {
    var callbacksToRemove: [AnyHashable] = []

    for callback in callbacks {
      if listener.isEqual(callback.listener) {
        callbacksToRemove.append(callback)
      }
    }
    var callbacksCopy = callbacks
    callbacksCopy = callbacksCopy.filter({ !callbacksToRemove.contains($0) })
    callbacks = callbacksCopy
  }

  private var callbacks: [STPURLCallback] = []
}

class STPURLCallback: NSObject {
  var urlComponents: NSURLComponents?
  weak var listener: STPURLCallbackListener?
}
