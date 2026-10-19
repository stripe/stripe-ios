import Foundation
import PassKit

/// Collects the optional Apple Pay telemetry signal without waiting for PassKit on the caller.
final class DeviceSupportsApplePayCollector {
    private let queue: DispatchQueue
    private let checkApplePaySupport: ([PKPaymentNetwork]) -> Bool
    private let lock = NSLock()
    private var result: (networks: [PKPaymentNetwork], value: Bool)?
    private var isChecking = false

    init(
        queue: DispatchQueue = DispatchQueue(label: "com.stripe.telemetry.apple-pay", qos: .utility),
        checkApplePaySupport: @escaping ([PKPaymentNetwork]) -> Bool = {
            PKPaymentAuthorizationController.canMakePayments(usingNetworks: $0)
        }
    ) {
        self.queue = queue
        self.checkApplePaySupport = checkApplePaySupport
    }

    var value: Bool? {
        let networks = StripeAPI.supportedPKPaymentNetworks()
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
            let value = self.checkApplePaySupport(networks)
            self.lock.lock()
            self.result = (networks, value)
            self.isChecking = false
            self.lock.unlock()
        }
        return nil
    }
}
