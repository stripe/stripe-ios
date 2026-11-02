//
//  CustomerProviderTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/27/26.
//

@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@_spi(InternalOnlyAPI) import StripeUICore
import XCTest

@MainActor
final class CustomerProviderTests: XCTestCase {

    func testNoCustomerHasNoIdentity() {
        let provider = CustomerProvider(customer: nil)

        XCTAssertFalse(provider.hasCustomer)
        XCTAssertNil(provider.customerID)
    }

    func testMerchantCustomerIdentity() {
        let customers: [PaymentSheet.CustomerConfiguration] = [
            .init(id: "cus_merchant", ephemeralKeySecret: "ek_test"),
            .init(id: "cus_merchant", customerSessionClientSecret: "cuss_test"),
        ]

        for customer in customers {
            let provider = CustomerProvider(customer: customer)

            XCTAssertTrue(provider.hasCustomer)
            XCTAssertEqual(provider.customerID, "cus_merchant")
        }
    }

    func testCheckoutCustomerIdentity() {
        let session = CheckoutTestHelpers.makeSession()
            .withCustomer(id: "cus_checkout")
            .makePublicSession()
        let provider = CustomerProvider(checkoutSession: session)

        XCTAssertTrue(provider.hasCustomer)
        XCTAssertEqual(provider.customerID, "cus_checkout")

        let guestProvider = CustomerProvider(
            checkoutSession: CheckoutTestHelpers.makeSession().makePublicSession()
        )
        XCTAssertFalse(guestProvider.hasCustomer)
        XCTAssertNil(guestProvider.customerID)
    }

    func testLoaderOrdersSavedMethodsUsingCheckoutCustomerDefault() {
        // Given different local defaults for the merchant and Checkout customers
        let merchantCustomerID = "cus_merchant_default"
        let checkoutCustomerID = "cus_checkout_default"
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: merchantCustomerID, ephemeralKeySecret: "ek_test")
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": checkoutCustomerID,
                "payment_methods": [
                    ["id": "pm_merchant_default", "type": "card", "created": 12345],
                    ["id": "pm_checkout_default", "type": "card", "created": 12345],
                ],
            ],
        ]).makePublicSession()
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId("pm_merchant_default"),
            forCustomer: merchantCustomerID
        )
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId("pm_checkout_default"),
            forCustomer: checkoutCustomerID
        )
        defer {
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: merchantCustomerID)
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: checkoutCustomerID)
        }

        // When the loader orders the Checkout session's saved payment methods
        let paymentMethods = PaymentSheetLoader.filterSavedPaymentMethods(
            intent: .checkout(session),
            elementsSession: session.elementsSession,
            configuration: configuration,
            customerProvider: CustomerProvider(checkoutSession: session),
            prefetchedSPMs: nil
        )

        // Then the Checkout customer's default takes priority over the merchant's default
        XCTAssertEqual(paymentMethods.map(\.stripeId), ["pm_checkout_default", "pm_merchant_default"])
    }
}
