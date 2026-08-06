import OHHTTPStubs
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
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

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
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

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "US",
            line1: "123 Shipping St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105-1234"
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
        XCTAssertEqual(requests[1].params["tax_region[postal_code]"], "94105")
        XCTAssertEqual(checkout.session.shippingAddress?.name, "Shipping Name")
        XCTAssertEqual(checkout.session.shippingAddress?.address.postalCode, "94105")
        XCTAssertEqual(
            checkout.getPaymentElement().paymentSheetFlowController.configuration.shippingDetails()?.address.postalCode,
            "94105"
        )
        XCTAssertEqual(
            checkout.getPaymentElement().embeddedPaymentElement.configuration.shippingDetails()?.address.postalCode,
            "94105"
        )
    }

    func testInitDoesNotApplyShippingDefaultWhenShippingAddressElementReturnsNil() async throws {
        // Given a Checkout Session that uses shipping for tax
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "US",
            line1: "123 Shipping St",
            city: "San Francisco",
            state: "CA",
            postalCode: "12"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes
        let checkout = try await Checkout(configuration: configuration)

        // Then the invalid shipping default remains in the SAE for correction but is not applied
        XCTAssertNotNil(checkout.getPaymentElement())
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(
            checkout.getShippingAddressElement().addressViewController.configuration.defaultValues.address.postalCode,
            "12"
        )
        let normalizedShippingAddress = await checkout.getShippingAddressElement().normalizedInitialShippingAddress()
        XCTAssertNil(normalizedShippingAddress)
    }

    func testInitDropsStateWhenShippingAddressElementDoesNotCollectState() async throws {
        // Given an address with a state for a country whose form does not collect one
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping", allowedShippingCountries: ["AT"])

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "AT",
            line1: "Karntner Strasse 1",
            city: "Vienna",
            state: "Vienna",
            postalCode: "1010"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes
        let checkout = try await Checkout(configuration: configuration)
        let requests = requestRecorder.requests

        // Then the SAE does not show or return the provided state
        XCTAssertNil(checkout.getShippingAddressElement().addressViewController.addressSection?.state)
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertNil(requests[1].params["tax_region[state]"])
        XCTAssertNil(checkout.session.shippingAddress?.address.state)
    }

    func testInitLeavesStateBlankWhenShippingAddressElementDoesNotRecognizeState() async throws {
        // Given a Brazilian state name that does not match an SDK state name or code
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping", allowedShippingCountries: ["BR"])

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "BR",
            line1: "Avenida Sete de Setembro 1",
            city: "Porto Velho",
            state: "Rondonia",
            postalCode: "76801-020"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes
        let checkout = try await Checkout(configuration: configuration)

        // Then the required state dropdown remains blank and the invalid address is not applied
        XCTAssertEqual(checkout.getShippingAddressElement().addressViewController.addressSection?.state?.rawData, "")
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
    }

    func testInitDoesNotApplyDisallowedShippingDefault() async throws {
        // Given a Checkout Session that only allows US shipping addresses
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping", allowedShippingCountries: ["US"])

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "CA",
            line1: "123 Front St",
            city: "Toronto",
            state: "ON",
            postalCode: "M5J 2N1"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes
        let checkout = try await Checkout(configuration: configuration)

        // Then the SAE rejects the default and Checkout does not apply it
        XCTAssertNotNil(checkout.getPaymentElement())
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertTrue(
            checkout.getShippingAddressElement().addressViewController.configuration.defaultValues.address.isEmpty
        )
    }

    func testInitWithoutShippingDefaultDoesNotPerformShippingUpdate() async throws {
        // Given a Checkout Session that uses shipping for tax
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = Checkout.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")

        // When Checkout initializes
        let checkout = try await Checkout(configuration: configuration)

        // Then Checkout does not manufacture or apply a shipping default
        XCTAssertNotNil(checkout.getPaymentElement())
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
    }

    // MARK: - Stubs

    private func stubCheckoutSessionRequests(
        automaticTaxAddressSource: String = "billing",
        allowedShippingCountries: [String] = ["US", "CA"]
    ) {
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: sessionId,
            requestRecorder: requestRecorder,
            sessionJSON: { [self] in
                sessionJSON(
                    automaticTaxAddressSource: automaticTaxAddressSource,
                    allowedShippingCountries: allowedShippingCountries
                )
            }
        )
    }

    private func sessionJSON(
        automaticTaxAddressSource: String = "billing",
        allowedShippingCountries: [String] = ["US", "CA"]
    ) -> [AnyHashable: Any] {
        var json = CheckoutTestHelpers.openSessionJSON
        json["session_id"] = sessionId
        json["client_secret"] = clientSecret
        json["tax_context"] = [
            "automatic_tax_enabled": true,
            "automatic_tax_address_source": "session.\(automaticTaxAddressSource)",
        ]
        json["shipping_address_collection"] = ["allowed_countries": allowedShippingCountries]
        return json
    }
}
