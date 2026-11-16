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

    // MARK: - Helpers

    private func makeSession(requiresShipping: Bool) -> CheckoutElementsController.Session {
        var overrides: [String: Any] = [:]
        if requiresShipping {
            overrides["shipping_address_collection"] = ["allowed_countries": ["US"]]
        }
        return CheckoutTestHelpers.makeSession(overrides).makePublicSession()
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

    private func makeShippingAddress() -> ShippingAddressesResponse.ShippingAddress {
        .init(
            id: "csmrshpad_123",
            address: .init(
                administrativeArea: "CA",
                countryCode: "US",
                dependentLocality: nil,
                line1: "510 Townsend St",
                line2: nil,
                locality: "San Francisco",
                name: "Jane Doe",
                postalCode: "94103",
                sortingCode: nil
            ),
            isDefault: true,
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
