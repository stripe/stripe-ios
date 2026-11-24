//
//  CheckoutLinkShippingAddressTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) @_spi(CheckoutSessionPreview) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutLinkShippingAddressTests: XCTestCase {

    func testLinkShippingAddressIsUsedWhenSessionRequiresShipping() {
        // Given a session that requires shipping and a Link selection with a shipping address
        let session = makeSession(requiresShipping: true)
        let confirmOption = makeConfirmOption(shippingAddress: makeShippingAddress())

        // When
        let params = CheckoutElementsController.linkShippingDetailsParams(for: confirmOption, checkoutSession: session)

        // Then the Link shipping address is sent
        XCTAssertNotNil(confirmOption.shippingAddress?.phone, "Expected the Link account's phone number on the confirm option")
        XCTAssertEqual(params?.name, "Jane Doe")
        XCTAssertEqual(params?.address.line1, "510 Townsend St")
        XCTAssertEqual(params?.address.city, "San Francisco")
        XCTAssertEqual(params?.address.state, "CA")
        XCTAssertEqual(params?.address.postalCode, "94103")
        XCTAssertEqual(params?.address.country, "US")
        // ...without the Link account's phone number, which Checkout Session confirmation rejects
        XCTAssertNil(params?.phone)
    }

    func testLinkShippingAddressIsIgnoredWhenSessionDoesNotRequireShipping() {
        // Given a session that doesn't collect shipping
        let session = makeSession(requiresShipping: false)
        let confirmOption = makeConfirmOption(shippingAddress: makeShippingAddress())

        // Then no shipping is sent
        XCTAssertNil(CheckoutElementsController.linkShippingDetailsParams(for: confirmOption, checkoutSession: session))
    }

    func testLinkShippingAddressIsIgnoredWhenNoneIsSelected() {
        // Given a session that requires shipping, but no Link shipping address
        let session = makeSession(requiresShipping: true)
        let confirmOption = makeConfirmOption(shippingAddress: nil)

        // Then no shipping is sent, so Checkout falls back to its own shipping address
        XCTAssertNil(CheckoutElementsController.linkShippingDetailsParams(for: confirmOption, checkoutSession: session))
    }

    func testTotalUsesSelectedShippingAddressWhenTaxUsesShippingAddress() {
        // Given a session whose tax is calculated from the shipping address, and a selected Link shipping address
        let context = makeLinkContext(taxAddressSource: "shipping")
        context.shippingAddresses = [makeShippingAddress()]
        context.selectedShippingAddressID = "csmrshpad_123"

        // When
        let address = context.totalAddress(for: makePaymentDetails(billingCountry: "CA"))

        // Then the total is calculated from the shipping address, not the billing address
        XCTAssertEqual(address?.line1, "510 Townsend St")
        XCTAssertEqual(address?.city, "San Francisco")
        XCTAssertEqual(address?.state, "CA")
        XCTAssertEqual(address?.postalCode, "94103")
        XCTAssertEqual(address?.country, "US")
    }

    func testTotalUsesBillingAddressWhenTaxUsesBillingAddress() {
        // Given a session whose tax is calculated from the billing address, and a selected Link shipping address
        let context = makeLinkContext(taxAddressSource: "billing")
        context.shippingAddresses = [makeShippingAddress()]
        context.selectedShippingAddressID = "csmrshpad_123"

        // When
        let address = context.totalAddress(for: makePaymentDetails(billingCountry: "CA"))

        // Then the total is calculated from the payment method's billing address
        XCTAssertEqual(address?.country, "CA")
    }

    func testSessionShippingAddressIsOfferedAndSelectedBeforeLinkDefault() {
        // Given a session with a shipping address that isn't saved to the Link account
        let context = makeLinkContext(sessionShippingAddress: makeSessionShippingAddress(line1: "1 Market St"))

        // When the Link account's addresses load, including a default one
        context.setSavedShippingAddresses([makeShippingAddress()])
        context.selectDefaultShippingAddressIfNeeded()

        // Then the session's address is offered first, and selected over the Link account's default
        XCTAssertEqual(context.shippingAddresses.map(\.id), [ShippingAddressesResponse.ShippingAddress.checkoutShippingAddressID, "csmrshpad_123"])
        XCTAssertEqual(context.selectedShippingAddress?.address.name, "Jane Doe")
        XCTAssertEqual(context.selectedShippingAddress?.address.line1, "1 Market St")
        XCTAssertEqual(context.selectedShippingAddress?.address.locality, "San Francisco")
        XCTAssertEqual(context.selectedShippingAddress?.address.administrativeArea, "CA")
        XCTAssertEqual(context.selectedShippingAddress?.address.postalCode, "94103")
        XCTAssertEqual(context.selectedShippingAddress?.address.countryCode, "US")
        // ...and it can't be removed, since it isn't saved to the Link account
        XCTAssertFalse(context.isShippingAddressSaved(context.shippingAddresses[0]))
        XCTAssertTrue(context.isShippingAddressSaved(context.shippingAddresses[1]))
    }

    func testSessionShippingAddressIsOfferedToNewLinkCustomers() {
        // Given a session with a shipping address, and a Link account without saved addresses
        let context = makeLinkContext(sessionShippingAddress: makeSessionShippingAddress(line1: "1 Market St"))

        // When
        context.setSavedShippingAddresses([])
        context.selectDefaultShippingAddressIfNeeded()

        // Then the session's address is selected, so the customer doesn't need to add one
        XCTAssertEqual(context.selectedShippingAddressID, ShippingAddressesResponse.ShippingAddress.checkoutShippingAddressID)
    }

    func testMatchingSavedShippingAddressIsSelectedInsteadOfDuplicatingSessionShippingAddress() {
        // Given a session whose shipping address is also saved to the Link account, with different casing
        let context = makeLinkContext(sessionShippingAddress: makeSessionShippingAddress(line1: "510 TOWNSEND ST"))
        let otherShippingAddress = makeShippingAddress(id: "csmrshpad_456", line1: "1 Market St", isDefault: true)

        // When
        context.setSavedShippingAddresses([otherShippingAddress, makeShippingAddress(isDefault: false)])
        context.selectDefaultShippingAddressIfNeeded()

        // Then the saved address is selected over the Link account's default, without adding a duplicate
        XCTAssertEqual(context.shippingAddresses.map(\.id), ["csmrshpad_456", "csmrshpad_123"])
        XCTAssertEqual(context.selectedShippingAddressID, "csmrshpad_123")
    }

    func testSessionShippingAddressIsIgnoredWhenSessionDoesNotRequireShipping() {
        // Given a session that doesn't collect shipping, but has a shipping address
        let context = makeLinkContext(
            requiresShipping: false,
            sessionShippingAddress: makeSessionShippingAddress(line1: "1 Market St")
        )

        // When
        context.setSavedShippingAddresses([makeShippingAddress()])
        context.selectDefaultShippingAddressIfNeeded()

        // Then only the Link account's addresses are offered
        XCTAssertEqual(context.shippingAddresses.map(\.id), ["csmrshpad_123"])
        XCTAssertEqual(context.selectedShippingAddressID, "csmrshpad_123")
    }

    // MARK: - Helpers

    private func makeSession(requiresShipping: Bool) -> CheckoutElementsController.Session {
        var overrides: [String: Any] = [:]
        if requiresShipping {
            overrides["shipping_address_collection"] = ["allowed_countries": ["US"]]
        }
        return CheckoutTestHelpers.makeSession(overrides).makePublicSession()
    }

    private func makeLinkContext(
        taxAddressSource: String? = nil,
        requiresShipping: Bool = true,
        sessionShippingAddress: CheckoutElementsController.Session.ShippingAddress? = nil
    ) -> PayWithLinkViewController.Context {
        var overrides: [String: Any] = [:]
        if requiresShipping {
            overrides["shipping_address_collection"] = ["allowed_countries": ["US"]]
        }
        if let taxAddressSource {
            overrides["automatic_tax"] = ["enabled": true, "status": "requires_address", "address_source": taxAddressSource]
        }
        var session = CheckoutTestHelpers.makeSession(overrides).makePublicSession()
        session.localState.shippingAddress = sessionShippingAddress
        let configuration = PaymentSheet.Configuration()
        return PayWithLinkViewController.Context(
            intent: .checkout(session),
            elementsSession: session.elementsSession,
            configuration: configuration,
            customerProvider: CustomerProvider(checkoutSession: session),
            linkBrand: .link,
            shouldOfferApplePay: false,
            shouldFinishOnClose: false,
            initiallySelectedPaymentDetailsID: nil,
            callToAction: nil,
            analyticsHelper: PaymentSheetAnalyticsHelper(integrationShape: .complete, configuration: configuration, analyticsClient: STPAnalyticsClient())
        )
    }

    private func makePaymentDetails(billingCountry: String) -> ConsumerPaymentDetails {
        let paymentDetails = LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card]
        return ConsumerPaymentDetails(
            stripeID: paymentDetails.stripeID,
            details: paymentDetails.details,
            billingAddress: BillingAddress(postalCode: "M5V 3L9", countryCode: billingCountry),
            billingEmailAddress: nil,
            nickname: nil,
            isDefault: true
        )
    }

    private func makeLinkAccountWithPhoneNumber() -> PaymentSheetLinkAccount {
        let session = ConsumerSession.make(
            clientSecret: "client_secret",
            emailAddress: "jane@example.com",
            redactedFormattedPhoneNumber: "+1********55",
            unredactedPhoneNumber: "+15555555555",
            phoneNumberCountry: "US",
            verificationSessions: [.init(type: .sms, state: .verified)],
            supportedPaymentDetailsTypes: [ParsedEnum(.card)],
            mobileFallbackWebviewParams: nil
        )
        return PaymentSheetLinkAccount(
            email: "jane@example.com",
            session: session,
            publishableKey: "pk_123",
            displayablePaymentDetails: nil,
            useMobileEndpoints: true,
            canSyncAttestationState: false
        )
    }

    private func makeSessionShippingAddress(line1: String) -> CheckoutElementsController.Session.ShippingAddress {
        .init(
            name: "Jane Doe",
            address: .init(country: "US", line1: line1, city: "San Francisco", state: "CA", postalCode: "94103")
        )
    }

    private func makeShippingAddress(
        id: String = "csmrshpad_123",
        line1: String = "510 Townsend St",
        isDefault: Bool = true
    ) -> ShippingAddressesResponse.ShippingAddress {
        .init(
            id: id,
            address: .init(
                administrativeArea: "CA",
                countryCode: "US",
                dependentLocality: nil,
                line1: line1,
                line2: nil,
                locality: "San Francisco",
                name: "Jane Doe",
                postalCode: "94103",
                sortingCode: nil
            ),
            isDefault: isDefault,
            nickname: nil
        )
    }

    private func makeConfirmOption(
        shippingAddress: ShippingAddressesResponse.ShippingAddress?
    ) -> PaymentSheet.LinkConfirmOption {
        .withPaymentDetails(
            brand: .link,
            account: makeLinkAccountWithPhoneNumber(),
            paymentDetails: LinkStubs.paymentMethods()[LinkStubs.PaymentMethodIndices.card],
            confirmationExtras: nil,
            shippingAddress: shippingAddress
        )
    }
}
