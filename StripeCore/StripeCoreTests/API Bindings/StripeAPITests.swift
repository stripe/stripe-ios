import PassKit
@_spi(InternalOnlyAPI) import StripeCore
import XCTest

final class StripeAPITests: XCTestCase {
    func testChinaUnionPayFilteringPreservesOneTimeAndUnconfiguredRequests() {
        // Given ordinary one-time requests and a builder request whose total is not configured yet
        for total in [nil, PKPaymentSummaryItem(label: "Total", amount: 10)] {
            let request = makeChinaUnionPayRequest()
            request.paymentSummaryItems = total.map { [$0] } ?? []

            // When applying request-only filtering
            StripeAPI.filterChinaUnionPay(for: request)

            // Then UnionPay and the other networks remain available
            XCTAssertEqual(request.supportedNetworks, [.visa, .chinaUnionPay, .cartesBancaires])
            XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .emv, .capabilityDebit])
        }
    }

    func testChinaUnionPayFilteringUsesGrandTotalRatherThanZeroLineItems() {
        let request = makeChinaUnionPayRequest()
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Discount", amount: .zero),
            PKPaymentSummaryItem(label: "Total", amount: 10),
        ]

        StripeAPI.filterChinaUnionPay(for: request)

        XCTAssertTrue(request.supportedNetworks.contains(.chinaUnionPay))
    }

    func testChinaUnionPayFilteringExcludesZeroTotalsAndIntentBasedSetups() {
        for (total, isSetupOrFutureOffSession) in [(0, false), (10, true)] {
            // Given a zero-total request or a positive-total request with an unsupported intent
            let request = makeChinaUnionPayRequest()
            request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(value: total), type: .pending)]

            // When applying filtering
            StripeAPI.filterChinaUnionPay(for: request, isSetupOrFutureOffSession: isSetupOrFutureOffSession)

            // Then only UnionPay and its EMV bit are removed, preserving other networks and funding bits
            XCTAssertEqual(request.supportedNetworks, [.visa, .cartesBancaires])
            XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityDebit])
        }
    }

    func testChinaUnionPayFilteringExcludesRecurringAndDeferredSummaryItems() {
        for item in [
            PKRecurringPaymentSummaryItem(label: "Subscription", amount: 10),
            PKDeferredPaymentSummaryItem(label: "Later payment", amount: 10),
        ] {
            let request = makeChinaUnionPayRequest()
            request.paymentSummaryItems = [item, PKPaymentSummaryItem(label: "Total", amount: 10)]

            StripeAPI.filterChinaUnionPay(for: request)

            XCTAssertEqual(request.supportedNetworks, [.visa, .cartesBancaires])
            XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityDebit])
        }
    }

    func testChinaUnionPayFilteringExcludesAutomaticReloadSummaryItems() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Automatic reload requires iOS 16") }
        let request = makeChinaUnionPayRequest()
        request.paymentSummaryItems = [
            PKAutomaticReloadPaymentSummaryItem(label: "Reload", amount: 10),
            PKPaymentSummaryItem(label: "Total", amount: 10),
        ]

        StripeAPI.filterChinaUnionPay(for: request)

        XCTAssertEqual(request.supportedNetworks, [.visa, .cartesBancaires])
    }

    func testChinaUnionPayFilteringExcludesRecurringAndReloadRequestFields() throws {
        guard #available(iOS 16.0, *) else { throw XCTSkip("Recurring and reload requests require iOS 16") }
        let managementURL = URL(string: "https://example.com/manage")!
        let recurringRequest = makeChinaUnionPayRequest()
        recurringRequest.recurringPaymentRequest = PKRecurringPaymentRequest(
            paymentDescription: "Subscription",
            regularBilling: PKRecurringPaymentSummaryItem(label: "Monthly", amount: 10),
            managementURL: managementURL
        )
        let reloadRequest = makeChinaUnionPayRequest()
        reloadRequest.automaticReloadPaymentRequest = PKAutomaticReloadPaymentRequest(
            paymentDescription: "Reload",
            automaticReloadBilling: PKAutomaticReloadPaymentSummaryItem(label: "Reload", amount: 10),
            managementURL: managementURL
        )

        for request in [recurringRequest, reloadRequest] {
            StripeAPI.filterChinaUnionPay(for: request)

            XCTAssertEqual(request.supportedNetworks, [.visa, .cartesBancaires])
            XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityDebit])
        }
    }

    func testChinaUnionPayFilteringExcludesDeferredRequestField() throws {
        guard #available(iOS 16.4, *) else { throw XCTSkip("Deferred requests require iOS 16.4") }
        let request = makeChinaUnionPayRequest()
        request.deferredPaymentRequest = PKDeferredPaymentRequest(
            paymentDescription: "Later payment",
            deferredBilling: PKDeferredPaymentSummaryItem(label: "Later payment", amount: 10),
            managementURL: URL(string: "https://example.com/manage")!
        )

        StripeAPI.filterChinaUnionPay(for: request)

        XCTAssertEqual(request.supportedNetworks, [.visa, .cartesBancaires])
        XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityDebit])
    }

    private func makeChinaUnionPayRequest() -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.supportedNetworks = [.visa, .chinaUnionPay, .cartesBancaires]
        request.merchantCapabilities = [.capability3DS, .emv, .capabilityDebit]
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Total", amount: 10)]
        return request
    }

    func testPaymentRequestWithChinaUnionPayAddsEMV() {
        // Given a merchant that has enabled China UnionPay
        let originalNetworks = StripeAPI.additionalEnabledApplePayNetworks
        StripeAPI.additionalEnabledApplePayNetworks = [.chinaUnionPay]
        defer { StripeAPI.additionalEnabledApplePayNetworks = originalNetworks }

        // When building a request for a custom integration
        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant_id", country: "CN", currency: "CNY")

        // Then UnionPay and EMV are both enabled, preserving 3DS
        XCTAssertTrue(request.supportedNetworks.contains(.chinaUnionPay))
        XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityEMV])
    }

    func testPaymentRequestWithoutChinaUnionPayDoesNotAddEMV() {
        let originalNetworks = StripeAPI.additionalEnabledApplePayNetworks
        StripeAPI.additionalEnabledApplePayNetworks = [.cartesBancaires]
        defer { StripeAPI.additionalEnabledApplePayNetworks = originalNetworks }

        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant_id", country: "FR", currency: "EUR")

        XCTAssertTrue(request.supportedNetworks.contains(.cartesBancaires))
        XCTAssertFalse(request.supportedNetworks.contains(.chinaUnionPay))
        XCTAssertEqual(request.merchantCapabilities, .capability3DS)
    }

    func testNormalizeEMVCapabilityForChinaUnionPayPreservesOtherCapabilities() {
        let request = PKPaymentRequest()
        request.supportedNetworks = [.visa, .chinaUnionPay]
        request.merchantCapabilities = [.capability3DS, .capabilityCredit, .capabilityDebit]

        StripeAPI.normalizeEMVCapabilityForChinaUnionPay(for: request)

        XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityEMV, .capabilityCredit, .capabilityDebit])
    }

    func testNormalizeEMVCapabilityAfterRemovingChinaUnionPayPreservesOtherCapabilities() {
        let request = PKPaymentRequest()
        request.supportedNetworks = [.visa]
        request.merchantCapabilities = [.capability3DS, .capabilityEMV, .capabilityCredit, .capabilityDebit]

        StripeAPI.normalizeEMVCapabilityForChinaUnionPay(for: request)

        XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityCredit, .capabilityDebit])
    }
}
