//
//  SavedPaymentMethodFormFactoryTests.swift
//  StripePaymentSheetTests
//

@_spi(STP) @testable import StripePaymentSheet
@testable import StripePaymentsTestUtils
@_spi(STP) import StripeUICore
import XCTest

final class SavedPaymentMethodFormFactoryTests: XCTestCase {

    let factory = SavedPaymentMethodFormFactory()

    // MARK: - currentBillingDetails

    func test_currentBillingDetails_pmHasBillingDetails_usesPaymentMethodValues() {
        let paymentMethod = STPPaymentMethod._testCard(
            line1: "123 Main St",
            city: "London",
            state: nil,
            postalCode: "SW1A 1AA",
            countryCode: "GB"
        )

        var defaultBillingDetails = PaymentSheet.BillingDetails()
        defaultBillingDetails.address.country = "US"
        defaultBillingDetails.address.city = "San Francisco"
        defaultBillingDetails.address.postalCode = "94102"

        let result = factory.currentBillingDetails(paymentMethod: paymentMethod,
                                                   defaultBillingDetails: defaultBillingDetails)

        XCTAssertEqual(result.address.country, "GB")
        XCTAssertEqual(result.address.city, "London")
        XCTAssertEqual(result.address.postalCode, "SW1A 1AA")
        XCTAssertEqual(result.address.line1, "123 Main St")
    }

    func test_currentBillingDetails_pmHasNoBillingDetails_usesDefaultBillingDetails() {
        // PM with no billing address
        let paymentMethod = STPPaymentMethod._testCard()

        var defaultBillingDetails = PaymentSheet.BillingDetails()
        defaultBillingDetails.address.country = "CA"
        defaultBillingDetails.address.city = "Toronto"
        defaultBillingDetails.address.line1 = "100 Queen St"
        defaultBillingDetails.address.postalCode = "M5H 2N2"

        let result = factory.currentBillingDetails(paymentMethod: paymentMethod,
                                                   defaultBillingDetails: defaultBillingDetails)

        XCTAssertEqual(result.address.country, "CA")
        XCTAssertEqual(result.address.city, "Toronto")
        XCTAssertEqual(result.address.line1, "100 Queen St")
        XCTAssertEqual(result.address.postalCode, "M5H 2N2")
    }

    func test_currentBillingDetails_pmHasNoBillingDetails_noDefaults_returnsNilFields() {
        let paymentMethod = STPPaymentMethod._testCard()
        let defaultBillingDetails = PaymentSheet.BillingDetails()

        let result = factory.currentBillingDetails(paymentMethod: paymentMethod,
                                                   defaultBillingDetails: defaultBillingDetails)

        XCTAssertNil(result.address.country)
        XCTAssertNil(result.address.city)
        XCTAssertNil(result.address.line1)
        XCTAssertNil(result.address.line2)
        XCTAssertNil(result.address.postalCode)
        XCTAssertNil(result.address.state)
    }

    func test_currentBillingDetails_pmHasPartialBillingDetails_doesNotFallbackToDefaults() {
        // PM has only postalCode set — city is nil on PM
        let paymentMethod = STPPaymentMethod._testCard(postalCode: "90210",
                                                       countryCode: "US")

        var defaultBillingDetails = PaymentSheet.BillingDetails()
        defaultBillingDetails.address.country = "DE"
        defaultBillingDetails.address.city = "Berlin"
        defaultBillingDetails.address.postalCode = "10115"

        let result = factory.currentBillingDetails(paymentMethod: paymentMethod,
                                                   defaultBillingDetails: defaultBillingDetails)

        // Should use PM values, not mix in defaults
        XCTAssertEqual(result.address.postalCode, "90210")
        XCTAssertEqual(result.address.country, "US")
        XCTAssertNil(result.address.city)
    }
}
