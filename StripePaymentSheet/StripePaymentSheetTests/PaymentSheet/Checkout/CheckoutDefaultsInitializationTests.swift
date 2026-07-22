import OHHTTPStubs
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutDefaultsInitializationTests: XCTestCase {
    private let sessionId = "cs_test_123"
    private let clientSecret = "cs_test_123_secret_abc"
    private let requestRecorder = CheckoutSessionRequestRecorder()

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testInitAppliesBillingDefaultThroughBillingTaxUpdateWhenNeeded() async throws {
        stubCheckoutSessionRequests()

        var configuration = Checkout.Configuration(clientSecret: clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.defaults = .init(
            billingDetails: .init(
                name: "Billing Name",
                address: .init(
                    country: "US",
                    line1: "123 Billing St",
                    city: "San Francisco",
                    state: "CA",
                    postalCode: "94105"
                )
            )
        )

        let checkout = try await Checkout(configuration: configuration)
        let requests = requestRecorder.requests

        XCTAssertNotNil(checkout.getPaymentElement())
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(requests[1].params["tax_region[country]"], "US")
        XCTAssertEqual(requests[1].params["tax_region[line1]"], "123 Billing St")
        XCTAssertEqual(requests[1].params["tax_region[city]"], "San Francisco")
    }

    // MARK: - Stubs

    private func stubCheckoutSessionRequests(
        automaticTaxAddressSource: String = "billing"
    ) {
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: sessionId,
            requestRecorder: requestRecorder,
            sessionJSON: { [self] in
                sessionJSON(automaticTaxAddressSource: automaticTaxAddressSource)
            }
        )
    }

    private func sessionJSON(
        automaticTaxAddressSource: String = "billing"
    ) -> [AnyHashable: Any] {
        var json = CheckoutTestHelpers.openSessionJSON
        json["session_id"] = sessionId
        json["client_secret"] = clientSecret
        json["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.\(automaticTaxAddressSource)",
        ]
        json["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        return json
    }
}
