import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripeUICore
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

    func testInitStoresDefaultEmailLocally() async throws {
        // Given an email in Checkout defaults
        stubCheckoutSessionRequests()
        var configuration = CheckoutController.Configuration(
            clientSecret: clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.defaults.email = "local@example.com"

        // When initializing CheckoutController
        let checkout = try await CheckoutController(configuration: configuration)

        // Then the default becomes the Session email
        XCTAssertEqual(checkout.session.localState.email, "local@example.com")
        XCTAssertEqual(checkout.session.email, "local@example.com")
    }

    func testInitAppliesBillingDefaultThroughBillingTaxUpdateWhenNeeded() async throws {
        AnalyticsHelper.shared.generateSessionID()
        let previousAnalyticsSessionID = AnalyticsHelper.shared.sessionID
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }
        stubCheckoutSessionRequests()

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.merchantDisplayName = "Test merchant"
        configuration.paymentElement = .init()
        configuration.paymentElement?.displaysMandateText = false
        configuration.paymentElement?.paymentMethodOrder = ["card", "ideal"]
        configuration.paymentElement?.removeSavedPaymentMethodMessage = "Remove this card?"
        var billingDetails = CheckoutController.Configuration.Defaults.BillingDetails()
        billingDetails.name = "Billing Name"
        billingDetails.address = .init(
            country: "US",
            line1: "123 Billing St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105"
        )
        configuration.defaults.billingDetails = billingDetails

        let checkout = try await CheckoutController(configuration: configuration)
        let requests = requestRecorder.requests

        XCTAssertNotNil(checkout.paymentElement)
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(requests.map { $0.params["client_secret"] }, [clientSecret, clientSecret])
        XCTAssertEqual(requests[1].params["tax_region[country]"], "US")
        XCTAssertEqual(requests[1].params["tax_region[line1]"], "123 Billing St")
        XCTAssertEqual(requests[1].params["tax_region[city]"], "San Francisco")

        // Initialization includes the default-address update even before the elements exist.
        let events = analyticsClient._testLogHistory.filter {
            ($0["event"] as? String)?.hasPrefix("checkout_elements.") == true
        }
        XCTAssertEqual(events.compactMap { $0["event"] as? String }, [
            "checkout_elements.init.started",
            "checkout_elements.update_billing_address.started",
            "checkout_elements.update_billing_address.succeeded",
            "checkout_elements.init.succeeded",
        ])
        // Initialization starts a fresh analytics session, shared by its nested address update.
        let analyticsSessionID = try XCTUnwrap(AnalyticsHelper.shared.sessionID)
        XCTAssertNotEqual(analyticsSessionID, previousAnalyticsSessionID)
        for event in events {
            XCTAssertEqual(event["session_id"] as? String, analyticsSessionID)
        }
        let billingUpdate = try XCTUnwrap(events.first { $0["event"] as? String == "checkout_elements.update_billing_address.succeeded" })
        XCTAssertEqual(billingUpdate["invocation_source"] as? String, "merchant")
        XCTAssertEqual(billingUpdate["did_request_tax_update"] as? Bool, true)

        // Both init events serialize configuration, including presence flags instead of customer text.
        let expectedConfiguration: [String: Any] = [
            "merchant_display_name": true,
            "defaults": [
                "billing_details": ["name": true, "address": true],
                "shipping_details": ["name": false, "address": false],
                "email": false,
                "phone": false,
            ],
            "payment_element": [
                "apple_pay_config": false,
                "link_display": "automatic",
                "save_payment_method_opt_in_behavior": "automatic",
                "appearance": try XCTUnwrap(configuration.paymentElement).appearance.analyticPayload,
                "remove_saved_payment_method_message": true,
                "opens_card_scanner_automatically": false,
                "terms_display": [String: String](),
                "payment_method_layout": "automatic",
                "displays_mandate_text": false,
                "payment_method_order": ["card", "ideal"],
                "row_selection_behavior": "default",
            ],
            "express_checkout_element": NSNull(),
            "currency_selector_element": NSNull(),
            "shipping_address_element": NSNull(),
        ]
        for event in [try XCTUnwrap(events.first), try XCTUnwrap(events.last)] {
            let configurationPayload = event.filter { expectedConfiguration.keys.contains($0.key) }
            XCTAssertEqual(configurationPayload as NSDictionary, expectedConfiguration as NSDictionary)
        }
    }

    func testInitAppliesShippingDefaultThroughShippingUpdateWhenNeeded() async throws {
        // Given a Checkout Session that uses shipping for tax
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()
        configuration.shippingAddressElement = .init()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
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
        let checkout = try await CheckoutController(configuration: configuration)
        let requests = requestRecorder.requests
        let paymentElement = checkout.getPaymentElement()

        // Then the shipping default is applied before PaymentElement loads
        XCTAssertNotNil(checkout.paymentElement)
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(requests[1].params["tax_region[country]"], "US")
        XCTAssertEqual(requests[1].params["tax_region[line1]"], "123 Shipping St")
        XCTAssertEqual(requests[1].params["tax_region[city]"], "San Francisco")
        XCTAssertEqual(requests[1].params["tax_region[postal_code]"], "94105")
        XCTAssertEqual(checkout.session.shippingAddress?.name, "Shipping Name")
        XCTAssertEqual(checkout.session.shippingAddress?.address.postalCode, "94105")
        XCTAssertEqual(
            paymentElement.paymentSheetFlowController.configuration.shippingDetails()?.address.postalCode,
            "94105"
        )
        XCTAssertEqual(
            paymentElement.embeddedPaymentElement.configuration.shippingDetails()?.address.postalCode,
            "94105"
        )
    }

    func testInitDoesNotNormalizeShippingDefaultWhenShippingAddressElementIsNotConfigured() async throws {
        // Given a Checkout Session that uses shipping for tax and a shipping default with an
        // extended postal code
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "US",
            line1: "123 Shipping St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105-1234"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes without Shipping Address Element
        let checkout = try await CheckoutController(configuration: configuration)
        let requests = requestRecorder.requests

        // Then the shipping default is applied without adapting it to the SAE form
        XCTAssertEqual(requests.map(\.kind), [.initSession, .updateSession])
        XCTAssertEqual(requests[1].params["tax_region[postal_code]"], "94105-1234")
        XCTAssertEqual(checkout.session.shippingAddress?.address.postalCode, "94105-1234")
    }

    func testInitDoesNotApplyShippingDefaultWhenShippingAddressElementReturnsNil() async throws {
        // Given a Checkout Session that uses shipping for tax
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()
        configuration.shippingAddressElement = .init()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
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
        let checkout = try await CheckoutController(configuration: configuration)

        // Then the invalid shipping default remains in the SAE for correction but is not applied
        XCTAssertNotNil(checkout.paymentElement)
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

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()
        configuration.shippingAddressElement = .init()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
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
        let checkout = try await CheckoutController(configuration: configuration)
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

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()
        configuration.shippingAddressElement = .init()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
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
        let checkout = try await CheckoutController(configuration: configuration)

        // Then the required state dropdown remains blank and the invalid address is not applied
        XCTAssertEqual(checkout.getShippingAddressElement().addressViewController.addressSection?.state?.rawData, "")
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
    }

    func testInitWithoutShippingDefaultDoesNotPerformShippingUpdate() async throws {
        // Given a Checkout Session that uses shipping for tax
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()

        // When Checkout initializes
        let checkout = try await CheckoutController(configuration: configuration)

        // Then Checkout does not manufacture or apply a shipping default
        XCTAssertNotNil(checkout.paymentElement)
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
    }

    func testInitIgnoresShippingDefaultWithDisallowedCountry() async throws {
        // Given a Checkout Session that does not allow the default shipping address's country
        stubCheckoutSessionRequests(automaticTaxAddressSource: "shipping")

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.paymentElement = .init()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Shipping Name"
        shippingDetails.address = .init(
            country: "GB",
            line1: "123 Shipping St",
            city: "London",
            postalCode: "SW1A 1AA"
        )
        configuration.defaults.shippingDetails = shippingDetails

        // When Checkout initializes
        let checkout = try await CheckoutController(configuration: configuration)
        let paymentElement = checkout.getPaymentElement()

        // Then the shipping default is treated as nil
        XCTAssertEqual(requestRecorder.requests.map(\.kind), [.initSession])
        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertNil(paymentElement.paymentSheetFlowController.configuration.shippingDetails())
        XCTAssertNil(paymentElement.embeddedPaymentElement.configuration.shippingDetails())
    }

    func testInitLoadsAddressSpecsWithoutPaymentElement() async throws {
        // Given an ECE-only Checkout integration and address specs that haven't been loaded yet
        stubCheckoutSessionRequests()
        let originalAddressSpecProvider = AddressSpecProvider.shared
        AddressSpecProvider.shared = AddressSpecProvider()
        defer { AddressSpecProvider.shared = originalAddressSpecProvider }
        XCTAssertTrue(AddressSpecProvider.shared.countries.isEmpty)

        var configuration = CheckoutController.Configuration(clientSecret: clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        configuration.expressCheckoutElement = .init { _ in }

        // When Checkout initializes
        let checkout = try await CheckoutController(configuration: configuration)

        // Then address specs are loaded so address forms (e.g. in the Link wallet) have countries to show
        XCTAssertNil(checkout.paymentElement)
        XCTAssertFalse(AddressSpecProvider.shared.countries.isEmpty)
    }

    func testInitLooksUpLinkForExpressCheckout() async throws {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        defer { analyticsClient._testLogHistory = previousLogHistory }
        let previousAccount = LinkAccountContext.shared.account
        defer { LinkAccountContext.shared.account = previousAccount }

        // Given ECE offers Link, with PE either absent or explicitly hiding Link
        for hasPaymentElement in [false, true] {
            analyticsClient._testLogHistory = []
            LinkAccountContext.shared.account = nil
            let response = CheckoutTestHelpers.makeSessionWithWalletTypes(
                ["card", "link"],
                customerEmail: "foo@bar.com"
            )
            var configuration = CheckoutTestHelpers.makeConfiguration(
                apiResponse: response,
                paymentElementConfiguration: hasPaymentElement ? .init() : nil
            )
            configuration.paymentElement?.linkConfiguration = .init(display: .never)
            let lookup = expectation(description: "Lookup with PE configured: \(hasPaymentElement)")
            lookup.assertForOverFulfill = true
            let responseData = try FileMock.consumers_lookup_200.data()
            let stub = HTTPStubs.stubRequests(passingTest: { $0.url?.path == "/v1/consumers/sessions/lookup" }) { request in
                let params = RequestBodyTestHelpers.formEncodedBodyParams(from: request)
                XCTAssertEqual(params["email_address"], "foo@bar.com")
                lookup.fulfill()
                return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
            }
            defer { HTTPStubs.removeStub(stub) }

            // When Checkout initializes, without opening either element
            let checkout = try await CheckoutController(configuration: configuration)

            // Then the shared Link account is recognized before ECE can be used
            XCTAssertEqual(checkout.paymentElement != nil, hasPaymentElement)
            XCTAssertEqual(LinkAccountContext.shared.account?.email, "foo@bar.com")
            XCTAssertEqual(LinkAccountContext.shared.account?.isRegistered, true)
            let lookupEvent = try XCTUnwrap(analyticsClient._testLogHistory.first { $0["event"] as? String == "link.account_lookup.complete" })
            XCTAssertEqual(lookupEvent["checkout_session_id"] as? String, checkout.session.id)
            await fulfillment(of: [lookup], timeout: 1)
        }
    }

    func testInitLoadsLinkUsingSessionAfterApplyingDefaults() async throws {
        let previousAccount = LinkAccountContext.shared.account
        defer { LinkAccountContext.shared.account = previousAccount }
        LinkAccountContext.shared.account = nil

        // Given Link becomes available in the response to the default shipping address update
        let initialSession = CheckoutTestHelpers.makeSessionWithWalletTypes([], automaticTaxAddressSource: "shipping")
        let updatedSession = CheckoutTestHelpers.makeSessionWithWalletTypes(
            ["link"],
            automaticTaxAddressSource: "shipping",
            customerEmail: "foo@bar.com"
        )
        var configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: initialSession, paymentElementConfiguration: nil)
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
        shippingDetails.address = .init(country: "US", postalCode: "94105")
        configuration.defaults.shippingDetails = shippingDetails
        HTTPStubs.stubRequests(passingTest: { $0.url?.path == "/v1/checkout_client/cs_test/update" }) { _ in
            HTTPStubsResponse(jsonObject: updatedSession.allResponseFields, statusCode: 200, headers: nil)
        }
        let lookup = expectation(description: "Link lookup using updated session")
        let responseData = try FileMock.consumers_lookup_200.data()
        HTTPStubs.stubRequests(passingTest: { $0.url?.path == "/v1/consumers/sessions/lookup" }) { request in
            XCTAssertEqual(RequestBodyTestHelpers.formEncodedBodyParams(from: request)["email_address"], "foo@bar.com")
            lookup.fulfill()
            return HTTPStubsResponse(data: responseData, statusCode: 200, headers: nil)
        }

        // When Checkout initializes
        _ = try await CheckoutController(configuration: configuration)

        // Then Link has loaded using the updated eligibility and email before initialization completes
        XCTAssertEqual(LinkAccountContext.shared.account?.email, "foo@bar.com")
        await fulfillment(of: [lookup], timeout: 1)
    }

    func testInitSkipsLinkLookupWhenBothElementsDisableLink() async throws {
        // Given Link is supported by the session but disabled in both elements
        let response = CheckoutTestHelpers.makeSessionWithWalletTypes(["card", "link"], customerEmail: "foo@bar.com")
        var configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: response)
        configuration.paymentElement?.linkConfiguration = .init(display: .never)
        configuration.expressCheckoutElement?.linkConfiguration.display = .never
        let lookup = expectation(description: "No Link lookup")
        lookup.isInverted = true
        HTTPStubs.stubRequests(passingTest: { $0.url?.path == "/v1/consumers/sessions/lookup" }) { _ in
            lookup.fulfill()
            return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
        }

        // When Checkout initializes
        _ = try await CheckoutController(configuration: configuration)

        // Then no background lookup is scheduled either
        await fulfillment(of: [lookup], timeout: 0.2)
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
        json["id"] = sessionId
        json["automatic_tax"] = [
            "enabled": true,
            "status": "requires_address",
            "address_source": automaticTaxAddressSource,
        ]
        json["shipping_address_collection"] = ["allowed_countries": allowedShippingCountries]
        return json
    }
}
