//
//  DispatchQueue+Throttle.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 21/12/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation

/// Adds throttling to dispatch queues
extension DispatchQueue {
    /// Dispatched actions' token storage
    private static var onceTokenStorage = Set<AnyHashable>()

    /**
     - parameters:
         - token: The control token for each dispatched action
         - action: The closure to be executed

     Dispatch the action only once for each given token
    */
    static func once(token: AnyHashable, action: () -> Void) {
        guard !onceTokenStorage.contains(token) else { return }

        defer { objc_sync_exit(self) }
        objc_sync_enter(self)

        onceTokenStorage.insert(token)
        action()
    }
}
