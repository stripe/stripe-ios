//
//  LinkTotalUpdaterTests.swift
//  StripePaymentSheetTests
//

@_spi(InternalOnlyAPI) import StripePayments
@testable import StripePaymentSheet
import XCTest

@MainActor
final class LinkTotalUpdaterTests: XCTestCase {

    private let usAddress = LinkTotalUpdaterTests.makeAddress(line1: "1 Main St", city: "Seattle", state: "WA", postalCode: "98101", country: "US")
    private let caAddress = LinkTotalUpdaterTests.makeAddress(postalCode: "M5V 3L9", country: "CA")

    func testSync_updatesAmountAndReportsChange() async throws {
        // Given an updater that returns a higher total for any address
        let updater = LinkTotalUpdater(amount: 1000) { _ in 1100 }

        // When syncing a billing address
        let changed = try await updater.sync(billingAddress: usAddress)

        // Then the new total is applied and reported as a change
        XCTAssertTrue(changed)
        XCTAssertEqual(updater.amount, 1100)
        XCTAssertFalse(updater.isUpdating)
    }

    func testSync_sameAddressTwice_callsHandlerOnce() async throws {
        // Given
        var callCount = 0
        let updater = LinkTotalUpdater(amount: 1000) { _ in
            callCount += 1
            return 1100
        }

        // When syncing the same address twice
        try await updater.sync(billingAddress: usAddress)
        let changed = try await updater.sync(billingAddress: usAddress)

        // Then the second sync is a no-op
        XCTAssertFalse(changed)
        XCTAssertEqual(callCount, 1)
    }

    func testSync_concurrentRequests_appliesLatestResultAndRunsInOrder() async throws {
        // Given an updater whose handler records the order of requests
        var handledCountries: [String?] = []
        let updater = LinkTotalUpdater(amount: 1000) { address in
            handledCountries.append(address?.country)
            await Task.yield()
            return address?.country == "US" ? 1100 : 1200
        }

        // When two addresses are synced back to back
        let first = Task { try await updater.sync(billingAddress: usAddress) }
        let second = Task { try await updater.sync(billingAddress: caAddress) }
        _ = try await (first.value, second.value)

        // Then requests ran in order and only the latest total is applied
        XCTAssertEqual(handledCountries, ["US", "CA"])
        XCTAssertEqual(updater.amount, 1200)
        XCTAssertFalse(updater.isUpdating)
    }

    func testSync_failure_allowsRetry() async {
        // Given an updater that fails once
        var shouldFail = true
        let updater = LinkTotalUpdater(amount: 1000) { _ in
            if shouldFail {
                shouldFail = false
                throw NSError(domain: "test", code: 0)
            }
            return 1100
        }

        // When the first sync fails
        do {
            try await updater.sync(billingAddress: usAddress)
            XCTFail("Expected an error")
        } catch {}
        XCTAssertEqual(updater.amount, 1000)
        XCTAssertFalse(updater.isUpdating)

        // Then syncing the same address again retries
        let changed = try? await updater.sync(billingAddress: usAddress)
        XCTAssertEqual(changed, true)
        XCTAssertEqual(updater.amount, 1100)
    }

    func testSync_withoutProgress_doesNotNotifyWhenTotalIsUnchanged() async throws {
        // Given an updater that keeps the same total
        let updater = LinkTotalUpdater(amount: 1000) { _ in 1000 }
        var notificationCount = 0
        updater.addObserver { notificationCount += 1 }

        // When syncing without showing progress
        let changed = try await updater.sync(billingAddress: usAddress, showsProgress: false)

        // Then observers aren't notified, since nothing visible changed
        XCTAssertFalse(changed)
        XCTAssertEqual(notificationCount, 0)
    }

    private static func makeAddress(
        line1: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String?,
        country: String
    ) -> STPPaymentMethodAddress {
        let address = STPPaymentMethodAddress()
        address.line1 = line1
        address.city = city
        address.state = state
        address.postalCode = postalCode
        address.country = country
        return address
    }
}
