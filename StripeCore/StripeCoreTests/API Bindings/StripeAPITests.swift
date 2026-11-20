import PassKit
@_spi(InternalOnlyAPI) import StripeCore
import XCTest

final class StripeAPITests: XCTestCase {
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
