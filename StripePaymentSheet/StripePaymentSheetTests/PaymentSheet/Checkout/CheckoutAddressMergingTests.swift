@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import XCTest

@MainActor
final class CheckoutAddressMergingTests: XCTestCase {

    func testApplyAddressOverrides_shippingApplied() {
        let apiResponse = CheckoutTestHelpers.makeOpenSession()
        let session = apiResponse.makePublicSession().makeCopyOverriding(shippingAddress: .newValue(Checkout.Session.ShippingAddress(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )))

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

    func testApplyAddressOverrides_configShippingTakesPrecedence() {
        let apiResponse = CheckoutTestHelpers.makeOpenSession()
        let session = apiResponse.makePublicSession().makeCopyOverriding(shippingAddress: .newValue(Checkout.Session.ShippingAddress(
            name: "John Smith",
            address: .init(country: "GB")
        )))

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
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com").makePublicSession()

        var config = PaymentSheet.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "session@example.com")
    }

    func testApplyAddressOverrides_configEmailTakesPrecedenceOverSession() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com").makePublicSession()

        var config = PaymentSheet.Configuration()
        config.defaultBillingDetails.email = "config@example.com"
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "config@example.com")
    }

    func testApplyAddressOverrides_noEmailStaysNil() {
        let session = CheckoutTestHelpers.makeOpenSession().makePublicSession()

        var config = PaymentSheet.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertNil(config.defaultBillingDetails.email)
    }

    // MARK: - EmbeddedPaymentElement.Configuration

    func testApplyAddressOverrides_embeddedShipping() {
        let apiResponse = CheckoutTestHelpers.makeOpenSession()
        let shippingAddress = Checkout.Session.ShippingAddress(
            name: "John Smith",
            address: .init(country: "US", line1: "456 Oak Ave", city: "LA", state: "CA", postalCode: "90001")
        )
        let session = apiResponse.makePublicSession().makeCopyOverriding(shippingAddress: .newValue(shippingAddress))

        var config = EmbeddedPaymentElement.Configuration()
        session.applyAddressOverrides(to: &config)

        let shipping = config.shippingDetails()
        XCTAssertNotNil(shipping)
        XCTAssertEqual(shipping?.name, "John Smith")
        XCTAssertEqual(shipping?.address.line1, "456 Oak Ave")
    }

    func testApplyAddressOverrides_embeddedEmailPopulatedFromSession() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com").makePublicSession()

        var config = EmbeddedPaymentElement.Configuration()
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "session@example.com")
    }

    func testApplyAddressOverrides_embeddedConfigEmailTakesPrecedence() {
        let session = CheckoutTestHelpers.makeOpenSession(customerEmail: "session@example.com").makePublicSession()

        var config = EmbeddedPaymentElement.Configuration()
        config.defaultBillingDetails.email = "config@example.com"
        session.applyAddressOverrides(to: &config)

        XCTAssertEqual(config.defaultBillingDetails.email, "config@example.com")
    }

    // MARK: - Billing address collection

    func testBillingRequired_upgradesAutomaticToFull() {
        let session = CheckoutTestHelpers.makeOpenSession(billingAddressCollection: "required").makePublicSession()

        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.address = .automatic
        session.applyAddressOverrides(to: &config)
        XCTAssertEqual(config.billingDetailsCollectionConfiguration.address, .full)
    }

    func testBillingRequired_fullStaysFull() {
        let session = CheckoutTestHelpers.makeOpenSession(billingAddressCollection: "required").makePublicSession()
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.address = .full
        session.applyAddressOverrides(to: &config)
        XCTAssertEqual(config.billingDetailsCollectionConfiguration.address, .full)
    }

    func testBillingAuto_doesntUpgradeAutomatic() {
        let session = CheckoutTestHelpers.makeOpenSession(billingAddressCollection: "auto").makePublicSession()
        var config = PaymentSheet.Configuration()
        config.billingDetailsCollectionConfiguration.address = .automatic
        session.applyAddressOverrides(to: &config)
        XCTAssertEqual(config.billingDetailsCollectionConfiguration.address, .automatic)
    }

    // MARK: - Billing address collection (embedded)

    func testEmbedded_billingRequired_upgradesAutomaticToFull() {
        let session = CheckoutTestHelpers.makeOpenSession(billingAddressCollection: "required").makePublicSession()
        var config = EmbeddedPaymentElement.Configuration()
        config.billingDetailsCollectionConfiguration.address = .automatic
        session.applyAddressOverrides(to: &config)
        XCTAssertEqual(config.billingDetailsCollectionConfiguration.address, .full)
    }

}
