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
        requestRecorder.removeAll()
        super.tearDown()
    }

    func testInitAppliesBillingDefaultThroughBillingTaxUpdateWhenNeeded() async throws {
        stubCheckoutSessionRequests()

        var configuration = Checkout.Configuration(clientSecret: clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var billingDetails = Checkout.Configuration.Defaults.BillingDetails()
        billingDetails.name = "Billing Name"
        billingDetails.address = .init(
            country: "US",
            line1: "123 Billing St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105"
        )
        configuration.defaults.billingDetails = billingDetails

        let checkout = try await Checkout(configuration: configuration)
        let requests = requestRecorder.requests

        XCTAssertNotNil(checkout.getPaymentElement())
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(requests[1].params["tax_region[country]"], "US")
        XCTAssertEqual(requests[1].params["tax_region[line1]"], "123 Billing St")
        XCTAssertEqual(requests[1].params["tax_region[city]"], "San Francisco")
    }

    func testInitAppliesShippingDefaultThroughShippingUpdateWhenNeeded() async throws {
        // Given a Checkout Session that uses shipping for tax
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = Checkout.Configuration(clientSecret: clientSecret)
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "US",
            line1: "123 Shipping St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes
        let checkout = try await Checkout(configuration: configuration)
        let requests = requestRecorder.requests

        // Then the shipping default is applied before PaymentElement loads
        XCTAssertNotNil(checkout.getPaymentElement())
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(requests[1].params["tax_region[country]"], "US")
        XCTAssertEqual(requests[1].params["tax_region[line1]"], "123 Shipping St")
        XCTAssertEqual(requests[1].params["tax_region[city]"], "San Francisco")
        XCTAssertEqual(checkout.session.shippingAddress?.name, "Shipping Name")
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
