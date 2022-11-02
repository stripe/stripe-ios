//
//  STPURLCallbackHandler.swift
//  StripeCore
//
//  Created by Brian Dorfman on 10/6/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

@_spi(STP) @objc public protocol STPURLCallbackListener: NSObjectProtocol {
    func handleURLCallback(_ url: URL) -> Bool
}

@_spi(STP) public class STPURLCallbackHandler: NSObject {
    @_spi(STP) public static var sharedHandler: STPURLCallbackHandler = STPURLCallbackHandler()

    @objc @_spi(STP) public class func shared() -> STPURLCallbackHandler {
        return sharedHandler
    }

    @objc @discardableResult @_spi(STP) public func handleURLCallback(_ url: URL) -> Bool {
        guard
            let components = NSURLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        else {
            return false
        }

        var resultsOrred = false

        for callback in callbacks {
            if let listener = callback.listener {
                if callback.urlComponents.stp_matchesURLComponents(components) {
                    resultsOrred = resultsOrred || listener.handleURLCallback(url)
                }
            }
        }

        return resultsOrred
    }

    @objc(registerListener:forURL:) @_spi(STP) public func register(
        _ listener: STPURLCallbackListener,
        for url: URL
    ) {

        guard
            let urlComponents = NSURLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        else {
            return
        }
        let callback = STPURLCallback(urlComponents: urlComponents, listener: listener)
        var callbacksCopy = callbacks
        callbacksCopy.append(callback)
        callbacks = callbacksCopy
    }

    @objc @_spi(STP) public func unregisterListener(_ listener: STPURLCallbackListener) {
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
    init(
        urlComponents: NSURLComponents,
        listener: STPURLCallbackListener
    ) {
        self.urlComponents = urlComponents
        self.listener = listener
        super.init()
    }

    var urlComponents: NSURLComponents
    weak var listener: STPURLCallbackListener?
}
