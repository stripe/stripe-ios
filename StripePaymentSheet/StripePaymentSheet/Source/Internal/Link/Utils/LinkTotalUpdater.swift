//
//  LinkTotalUpdater.swift
//  StripePaymentSheet
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePayments

/// Keeps the total shown in native Link in sync when it depends on the selected payment details' billing address,
/// e.g. for automatic tax calculated from the billing address.
///
/// The owner provides a handler that receives the billing address and returns the updated total in minor units.
/// Updates run one at a time in the order they were requested, and only the latest request's result is applied.
@MainActor
final class LinkTotalUpdater {
    typealias Handler = @MainActor (STPPaymentMethodAddress?) async throws -> Int

    enum Error: LocalizedError {
        case totalChanged

        var errorDescription: String? {
            return STPLocalizedString(
                "Your total was updated based on your billing address. Review it and try again.",
                "Error shown when the total changes after the customer taps the pay button, because tax depends on the billing address."
            )
        }
    }

    private let handler: Handler

    /// The total to display, in minor units.
    private(set) var amount: Int

    /// Whether an update is in flight that the UI should wait for.
    private(set) var isUpdating: Bool = false

    private var syncedKey: String?
    private var inFlight: (key: String, task: Task<Int, Swift.Error>)?
    private var observers: [(isAlive: () -> Bool, notify: () -> Void)] = []

    init(amount: Int, handler: @escaping Handler) {
        self.amount = amount
        self.handler = handler
    }

    /// Registers a closure that's called whenever `amount` or `isUpdating` changes, for as long as `owner` is alive.
    func addObserver<Owner: AnyObject>(_ owner: Owner, handler: @escaping (Owner) -> Void) {
        observers.append((
            isAlive: { [weak owner] in owner != nil },
            notify: { [weak owner] in
                guard let owner else { return }
                handler(owner)
            }
        ))
    }

    /// Syncs the total for the given billing address.
    /// - Parameter showsProgress: Whether to set `isUpdating` while the request is in flight.
    /// - Returns: Whether the total changed from the one displayed when this method was called.
    @discardableResult
    func sync(billingAddress: STPPaymentMethodAddress?, showsProgress: Bool = true) async throws -> Bool {
        let key = Self.key(for: billingAddress)
        let amountBefore = amount

        let task: Task<Int, Swift.Error>
        if let inFlight, inFlight.key == key {
            // Join the request that's already in flight for this address.
            task = inFlight.task
        } else if inFlight == nil, key == syncedKey {
            return false
        } else {
            let previousTask = inFlight?.task
            let handler = handler
            task = Task { @MainActor in
                // Wait for the previous request so the server applies updates in order.
                _ = try? await previousTask?.value
                return try await handler(billingAddress)
            }
            inFlight = (key, task)
            if showsProgress {
                isUpdating = true
                notifyObservers()
            }
        }

        do {
            let newAmount = try await task.value
            guard inFlight?.key == key else {
                // A newer request superseded this one. Its result will be applied instead.
                return newAmount != amountBefore
            }
            let shouldNotify = isUpdating || newAmount != amount
            inFlight = nil
            syncedKey = key
            amount = newAmount
            isUpdating = false
            if shouldNotify {
                notifyObservers()
            }
            return newAmount != amountBefore
        } catch {
            if inFlight?.key == key {
                inFlight = nil
                syncedKey = nil
                isUpdating = false
                notifyObservers()
            }
            throw error
        }
    }

    func syncInBackground(billingAddress: STPPaymentMethodAddress?, onError: @escaping @MainActor (Swift.Error) -> Void) {
        Task { @MainActor in
            do {
                try await sync(billingAddress: billingAddress)
            } catch {
                onError(error)
            }
        }
    }

    func waitUntilIdle() async {
        var awaitedTask: Task<Int, Swift.Error>?
        while let task = inFlight?.task, task != awaitedTask {
            _ = try? await task.value
            awaitedTask = task
        }
    }

    private func notifyObservers() {
        observers.removeAll { !$0.isAlive() }
        observers.forEach { $0.notify() }
    }

    private static func key(for billingAddress: STPPaymentMethodAddress?) -> String {
        return [
            billingAddress?.line1,
            billingAddress?.line2,
            billingAddress?.city,
            billingAddress?.state,
            billingAddress?.postalCode,
            billingAddress?.country,
        ].map { $0 ?? "" }.joined(separator: "|")
    }
}
