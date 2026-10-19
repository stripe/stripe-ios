import Foundation
import PassKit

/// Collects the optional Apple Pay telemetry signal without waiting for PassKit on the caller.
final class ApplePayCapability {
    private let queue: DispatchQueue
    private let check: ([PKPaymentNetwork]) -> Bool
    private let lock = NSLock()
    private var result: (networks: [PKPaymentNetwork], value: Bool)?
    private var isChecking = false

    init(
        queue: DispatchQueue = DispatchQueue(label: "com.stripe.telemetry.apple-pay", qos: .utility),
        check: @escaping ([PKPaymentNetwork]) -> Bool = {
            PKPaymentAuthorizationController.canMakePayments(usingNetworks: $0)
        }
    ) {
        self.queue = queue
        self.check = check
    }

    func cachedValue(for networks: [PKPaymentNetwork]) -> Bool? {
        lock.lock()
        defer { lock.unlock() }

        if let result, result.networks == networks {
            return result.value
        }
        // A stalled check must not accumulate more work with each telemetry request.
        guard !isChecking else { return nil }
        isChecking = true
        queue.async {
            // Never hold the lock while waiting on PassKit: readers must remain nonblocking.
            let value = self.check(networks)
            self.lock.lock()
            self.result = (networks, value)
            self.isChecking = false
            self.lock.unlock()
        }
        return nil
    }
}
