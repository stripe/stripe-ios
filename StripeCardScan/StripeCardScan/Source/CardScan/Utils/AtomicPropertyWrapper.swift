//
//  AtomicPropertyWrapper.swift
//  StripeCardScan
//
//  Created by Scott Grant on 7/5/22.
//

import Foundation

@propertyWrapper
class AtomicProperty<Value> {

    private var value: Value

    private lazy var lock: os_unfair_lock_t = {
        let lock = os_unfair_lock_t.allocate(capacity: 1)
        lock.initialize(to: os_unfair_lock_s())
        return lock
    }()

    init(
        wrappedValue value: Value
    ) {
        self.value = value
    }

    deinit {
        lock.deallocate()
    }

    var wrappedValue: Value {
        get {
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return value
        }
        set {
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            value = newValue
        }
    }
}
