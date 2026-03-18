@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutAddressMergingTests: XCTestCase {

    func testApplyAddressOverrides_billingFillsEmptyFields() {
        let session = CheckoutTestHelpers.makeOpenSession()
        session.billingAddressOverride = Checkout.AddressUpdate(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )

        var config = PaymentSheet.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.name, "Jane Doe")
        XCTAssertEqual(config.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(config.defaultBillingDetails.address.line1, "123 Main St")
        XCTAssertEqual(config.defaultBillingDetails.address.city, "SF")
        XCTAssertEqual(config.defaultBillingDetails.address.state, "CA")
        XCTAssertEqual(config.defaultBillingDetails.address.postalCode, "94105")
    }

    func testApplyAddressOverrides_billingConfigTakesPrecedence() {
        let session = CheckoutTestHelpers.makeOpenSession()
        session.billingAddressOverride = Checkout.AddressUpdate(
            name: "Override Name",
            address: .init(country: "GB", line1: "Override Line1")
        )

        var config = PaymentSheet.Configuration()
        config.defaultBillingDetails.name = "Config Name"
        config.defaultBillingDetails.address.country = "US"
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.name, "Config Name")
        XCTAssertEqual(config.defaultBillingDetails.address.country, "US")
        // line1 was empty in config, so override fills it
        XCTAssertEqual(config.defaultBillingDetails.address.line1, "Override Line1")
    }

    func testApplyAddressOverrides_shippingApplied() {
        let session = CheckoutTestHelpers.makeOpenSession()
        session.shippingAddressOverride = Checkout.AddressUpdate(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        var config = PaymentSheet.Configuration()
        XCTAssertNil(config.shippingDetails())
        session.applyAddressOverrides(to: &config)

        let details = config.shippingDetails()
        XCTAssertNotNil(details)
        XCTAssertEqual(details?.name, "John Smith")
        XCTAssertEqual(details?.address.country, "US")
        XCTAssertEqual(details?.address.line1, "456 Oak Ave")
        XCTAssertEqual(details?.address.city, "LA")
        XCTAssertEqual(details?.address.state, "CA")
        XCTAssertEqual(details?.address.postalCode, "90001")
    }

    func testApplyAddressOverrides_shippingNotOverriddenWhenConfigHasShipping() {
        let session = CheckoutTestHelpers.makeOpenSession()
        session.shippingAddressOverride = Checkout.AddressUpdate(
            name: "Override",
            address: .init(country: "GB")
        )

        var config = PaymentSheet.Configuration()
        let existingDetails = AddressViewController.AddressDetails(
            address: .init(country: "US", line1: "Existing"),
            name: "Existing Name",
            phone: nil
        )
        config.shippingDetails = { existingDetails }
        session.applyAddressOverrides(to: &config)

        let details = config.shippingDetails()
        XCTAssertEqual(details?.name, "Existing Name")
        XCTAssertEqual(details?.address.country, "US")
    }

    // MARK: - Email

    func testApplyAddressOverrides_emailPopulatedFromSession() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com")

        var config = PaymentSheet.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "session@example.com")
    }

    func testApplyAddressOverrides_configEmailTakesPrecedenceOverSession() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com")

        var config = PaymentSheet.Configuration()
        config.defaultBillingDetails.email = "config@example.com"
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "config@example.com")
    }

    func testApplyAddressOverrides_noEmailStaysNil() {
        let session = CheckoutTestHelpers.makeOpenSession()

        var config = PaymentSheet.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertNil(config.defaultBillingDetails.email)
    }

    // MARK: - EmbeddedPaymentElement.Configuration

    func testApplyAddressOverrides_embeddedBillingAndShipping() {
        let session = CheckoutTestHelpers.makeOpenSession()
        session.billingAddressOverride = Checkout.AddressUpdate(
            name: "Jane Doe",
            address: .init(country: "US", line1: "123 Main St", city: "SF", state: "CA", postalCode: "94105")
        )
        session.shippingAddressOverride = Checkout.AddressUpdate(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )

        var config = EmbeddedPaymentElement.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.name, "Jane Doe")
        XCTAssertEqual(config.defaultBillingDetails.address.country, "US")
        XCTAssertEqual(config.defaultBillingDetails.address.line1, "123 Main St")

        let shipping = config.shippingDetails()
        XCTAssertNotNil(shipping)
        XCTAssertEqual(shipping?.name, "John Smith")
        XCTAssertEqual(shipping?.address.line1, "456 Oak Ave")
    }

    func testApplyAddressOverrides_embeddedEmailPopulatedFromSession() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com")

        var config = EmbeddedPaymentElement.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "session@example.com")
    }

    func testApplyAddressOverrides_embeddedConfigEmailTakesPrecedence() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com")

        var config = EmbeddedPaymentElement.Configuration()
        config.defaultBillingDetails.email = "config@example.com"
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "config@example.com")
    }

}
