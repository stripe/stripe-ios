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
    /// Stores a throttle DispatchWorkItem instance for a given context
    private static var workItems = [AnyHashable: DispatchWorkItem]()

    /// Stores the last call times for a given context
    private static var lastDebounceCallTimes = [AnyHashable: DispatchTime]()

    /// Dispatched actions' token storage
    private static var onceTokenStorage = Set<AnyHashable>()

    /// An object representing a context if none is given
    private static let nilContext = UUID()

    /**
     - parameters:
         - deadline: The timespan to delay a closure execution
         - context: The context in which the throttle should be executed
         - action: The closure to be executed
     
     Delays a closure execution and ensures no other executions are made during deadline for that context
     */
    func throttle(deadline: DispatchTime, context: AnyHashable = nilContext, action: @escaping () -> Void) {
        let worker = DispatchWorkItem {
            defer { DispatchQueue.workItems.removeValue(forKey: context) }
            action()
        }

        asyncAfter(deadline: deadline, execute: worker)

        DispatchQueue.workItems[context]?.cancel()
        DispatchQueue.workItems[context] = worker
    }

    /**
     - parameters:
         - interval: The interval in which new calls will be ignored
         - context: The context in which the debounce should be executed
         - action: The closure to be executed

     Executes a closure and ensures no other executions will be made during the interval.
     */
    func debounce(interval: Double, context: AnyHashable = nilContext, action: @escaping () -> Void) {
        let now = DispatchTime.now()
        if let last = DispatchQueue.lastDebounceCallTimes[context], last + interval > now {
            return
        }

        DispatchQueue.lastDebounceCallTimes[context] = now + interval
        async(execute: action)

        // Cleanup & release context
        throttle(deadline: now + interval) {
            DispatchQueue.lastDebounceCallTimes.removeValue(forKey: context)
        }
    }

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
