import OHHTTPStubs
@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet
@testable @_spi(STP) import StripeUICore
import XCTest

@available(iOS 16.0, *)
@MainActor
final class CheckoutSheetTests: XCTestCase {
    override func tearDown() {
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testContactAndShippingUpdateTheSessionAndTax() async throws {
        // Given a session that requires a shipping address for automatic tax
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: shippingSessionJSON)
        let sheet = try await makeSheet(response)
        let model = sheet.model
        let requests = CheckoutSessionRequestRecorder()
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: response.sessionId,
            requestRecorder: requests,
            sessionJSON: { self.shippingSessionJSON }
        )
        XCTAssertEqual(model.tasks, [.contact, .shipping, .payment])
        XCTAssertFalse(model.canConfirm)
        XCTAssertFalse(model.canEdit(.payment))

        // When the customer saves contact information and a valid shipping address
        model.emailDraft = "jane@example.com"
        await model.saveContact()
        XCTAssertEqual(sheet.session.email, "jane@example.com")
        XCTAssertEqual(model.activeTask, .shipping)
        fillShipping(model)
        XCTAssertTrue(model.addressIsValid)
        await model.saveShipping()

        // Then the shared Checkout Session contains the collected details and sent the tax region
        XCTAssertEqual(sheet.session.shippingAddress?.name, "Jane Doe")
        XCTAssertEqual(sheet.session.shippingAddress?.address.line1, "510 Townsend St")
        XCTAssertEqual(requests.requests.last?.params["tax_region[country]"], "US")
        XCTAssertEqual(requests.requests.last?.params["tax_region[postal_code]"], "94103")
        XCTAssertNil(requests.requests.last?.params["tax_region[line2]"])
        XCTAssertEqual(model.activeTask, .payment)
        XCTAssertFalse(model.canConfirm)
        XCTAssertNil(model.errorMessage)
    }

    func testShippingFailurePreservesDraftAndDoesNotAdvance() async throws {
        // Given a valid draft and a server that rejects the tax update
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: shippingSessionJSON)
        let sheet = try await makeSheet(response)
        let model = sheet.model
        model.emailDraft = "jane@example.com"
        await model.saveContact()
        fillShipping(model)
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: response.sessionId,
            requestRecorder: CheckoutSessionRequestRecorder(),
            sessionJSON: { self.shippingSessionJSON },
            updateStatusCode: { _ in 400 }
        )

        // When the customer saves the address
        await model.saveShipping()

        // Then they can retry with their draft, without stale shipping details or an enabled pay action
        XCTAssertNotNil(model.errorMessage)
        XCTAssertNil(sheet.session.shippingAddress)
        XCTAssertEqual(model.activeTask, .shipping)
        XCTAssertEqual(model.addressSection.line1?.text, "510 Townsend St")
        XCTAssertFalse(model.isWorking)
        XCTAssertFalse(model.canConfirm)
    }

    func testShippingFormSurvivesZeroWidthLayoutAndRestoresFullWidth() async throws {
        // Given the real shipping form hosted by Checkout Sheet
        let response = try PaymentPagesAPIResponse.decode(fromAPIResponse: shippingSessionJSON)
        let sheet = try await makeSheet(response)
        fillShipping(sheet.model)
        let form = sheet.model.addressSection.view
        let container = CheckoutSheetElementContainer(elementView: form)

        // When SwiftUI temporarily lays out the wrapper at zero width
        container.frame = .zero
        container.setNeedsLayout()
        container.layoutIfNeeded()

        // Then the form retains enough width for its required field margins
        XCTAssertGreaterThan(form.bounds.width, 0)

        // When the wrapper receives its actual width
        let size = container.fittingSize(width: 320)
        container.frame = CGRect(origin: .zero, size: size)
        container.setNeedsLayout()
        container.layoutIfNeeded()

        // Then the form fills that width and all of its fields fit vertically
        XCTAssertEqual(size.width, 320)
        XCTAssertGreaterThan(size.height, 0)
        XCTAssertEqual(form.frame.minX, 0, accuracy: 0.5)
        XCTAssertEqual(form.bounds.width, size.width, accuracy: 0.5)
        XCTAssertEqual(form.bounds.height, size.height, accuracy: 0.5)
    }

    func testPromotionCodeRefreshesTheDisplayedSessionAmounts() async throws {
        // Given a Checkout Session that enables promotion codes
        let response = try PaymentPagesAPIResponse.decode(
            fromAPIResponse: CheckoutTestHelpers.makeSessionJSON(["allow_promotion_codes": true])
        )
        let sheet = try await makeSheet(response)
        let requests = CheckoutSessionRequestRecorder()
        CheckoutTestHelpers.stubCheckoutSessionRequests(
            sessionId: response.sessionId,
            requestRecorder: requests,
            sessionJSON: {
                let amount = requests.requests.last?.params["promotion_code"] == "SAVE10" ? 900 : 1000
                return CheckoutTestHelpers.makeSessionJSON([
                    "allow_promotion_codes": true,
                    "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: amount),
                ])
            }
        )

        // When a promotion is applied and then removed
        sheet.model.promotionCode = "SAVE10"
        await sheet.model.applyPromotionCode()

        // Then pricing comes from each server response, rather than local prototype arithmetic
        XCTAssertEqual(sheet.session.totals.total.minorUnitsAmount, 900)
        XCTAssertEqual(requests.requests.last?.params["promotion_code"], "SAVE10")
        XCTAssertTrue(sheet.session.allowsPromotionCodes)
        await sheet.model.removePromotionCode()
        XCTAssertEqual(sheet.session.totals.total.minorUnitsAmount, 1000)
        XCTAssertEqual(requests.requests.last?.params["promotion_code"], "")
    }

    func testServerEmailIsReadOnlyAndZeroAmountDoesNotRequirePayment() async throws {
        // Given a free Checkout Session with an immutable server email
        let response = try PaymentPagesAPIResponse.decode(
            fromAPIResponse: CheckoutTestHelpers.makeSessionJSON([
                "customer_email": "server@example.com",
                "checkout_items": CheckoutTestHelpers.makeOneTimePriceCheckoutItems(unitAmount: 0),
            ])
        )
        let sheet = try await makeSheet(response)

        // Then checkout can reach review without inventing a payment requirement
        XCTAssertEqual(sheet.model.tasks, [.contact])
        XCTAssertTrue(sheet.model.canConfirm)
        XCTAssertFalse(sheet.model.canEdit(.contact))

        // When an editor attempts to replace the server email
        sheet.model.emailDraft = "local@example.com"
        await sheet.model.saveContact()

        // Then the immutable email is retained
        XCTAssertEqual(sheet.session.email, "server@example.com")
    }

    func testFailedAndCanceledConfirmationAllowRetryWithoutSuccess() async throws {
        let sheet = try await makeSheet(CheckoutTestHelpers.makeOpenSession())
        sheet.model.isWorking = true
        sheet.model.handleConfirmationResult(.failed(NSError(domain: "test", code: 1)))
        XCTAssertNotNil(sheet.model.errorMessage)
        XCTAssertNil(sheet.model.completedPaymentStatus)
        XCTAssertFalse(sheet.model.isWorking)
        sheet.model.isWorking = true
        sheet.model.handleConfirmationResult(.canceled)
        XCTAssertNil(sheet.model.completedPaymentStatus)
        XCTAssertFalse(sheet.model.isWorking)
        sheet.model.handleConfirmationResult(.completed(paymentStatus: .unpaid))
        XCTAssertEqual(sheet.model.completedPaymentStatus, .unpaid)
    }

    func testSheetConfigurationOwnsItsElementsAndDerivesWalletShipping() {
        var config = CheckoutSheet.Configuration(
            clientSecret: "cs_test_secret_test",
            returnURL: "stripe-ios-test://checkout-return"
        )
        config.allowsLink = false
        config.allowsAdaptivePricing = false
        let checkout = CheckoutSheet.makeCheckoutConfiguration(config) { _ in }
        XCTAssertNotNil(checkout.paymentElement)
        XCTAssertNotNil(checkout.shippingAddressElement)
        XCTAssertNil(checkout.currencySelectorElement)
        XCTAssertEqual(checkout.expressCheckoutElement?.linkConfiguration.display, .never)
        XCTAssertEqual(checkout.expressCheckoutElement?.collectsShippingAddressIfRequired, true)
    }

    func testCallbackPresentationRetainsSheetUntilItReturnsTheResult() async throws {
        // Given a callback integration that only keeps the sheet while initializing it
        var sheet: CheckoutSheet? = try await makeSheet(CheckoutTestHelpers.makeOpenSession())
        weak var presentedSheet = sheet
        let window = UIWindow(frame: UIScreen.main.bounds)
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let resultReturned = expectation(description: "Checkout returns cancellation")

        // When checkout is presented and the merchant releases its reference
        sheet?.present(from: presenter) { result in
            guard case .canceled = result else {
                XCTFail("Closing an open checkout should cancel it.")
                resultReturned.fulfill()
                return
            }
            resultReturned.fulfill()
        }
        sheet = nil
        XCTAssertNotNil(presentedSheet)
        try await Task.sleep(nanoseconds: 500_000_000)
        presentedSheet?.model.close()

        // Then the completion runs once and the sheet releases its presentation lifetime
        await fulfillment(of: [resultReturned], timeout: 3)
        XCTAssertNil(presentedSheet)
    }

    private func makeSheet(_ response: PaymentPagesAPIResponse) async throws -> CheckoutSheet {
        var config = CheckoutSheet.Configuration(
            clientSecret: "\(response.sessionId)_secret_test",
            returnURL: "stripe-ios-test://checkout-return"
        )
        config.apiClient = CheckoutTestHelpers.makeStubbedAPIClient(apiResponse: response)
        return try await CheckoutSheet(configuration: config)
    }

    private var shippingSessionJSON: [String: Any] {
        CheckoutTestHelpers.makeSessionJSON([
            "shipping_address_collection": ["allowed_countries": ["US"]],
            "tax_context": ["automatic_tax_enabled": true, "automatic_tax_address_source": "shipping"],
        ])
    }

    private func fillShipping(_ model: CheckoutSheetModel) {
        model.addressSection.name?.setText("Jane Doe")
        model.addressSection.setAddress(
            .init(city: "San Francisco", country: "US", line1: "510 Townsend St", postalCode: "94103", state: "CA")
        )
    }
}
