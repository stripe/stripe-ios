//
//  STPPaymentMethodBillingDetailsTests.swift
//  StripeiOSTests
//
//  Created by Eduardo Urias on 2/27/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@testable import StripePaymentSheet
import XCTest

// Link mapping tests
final class STPPaymentMethodBillingDetailsTests: XCTestCase {
    func testConsumersAPIParamsMapping() {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Name"
        billingDetails.email = "Email"
        billingDetails.phone = "Phone"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "Line 1"
        billingDetails.address?.line2 = ""
        billingDetails.address?.city = "City"
        billingDetails.address?.state = "State"
        billingDetails.address?.country = "Country"

        let params = billingDetails.consumersAPIParams
        XCTAssertEqual(params["name"] as? String, "Name")
        XCTAssertEqual(params["line_1"] as? String, "Line 1")
        XCTAssertNil(params["line_2"])
        XCTAssertEqual(params["locality"] as? String, "City")
        XCTAssertEqual(params["administrative_area"] as? String, "State")
        XCTAssertEqual(params["country_code"] as? String, "Country")

        XCTAssertNil(params["email"])
        XCTAssertNil(params["phone"])
        XCTAssertNil(params["line1"])
        XCTAssertNil(params["line2"])
        XCTAssertNil(params["city"])
        XCTAssertNil(params["state"])
        XCTAssertNil(params["country"])
    }

    func testCreateLinkBillingAddress() {
        let billingAddress = BillingAddress(
            name: "Name",
            line1: "Line 1",
            line2: "Line 2",
            city: "City",
            state: "State",
            countryCode: "Country"
        )
        let billingDetails = STPPaymentMethodBillingDetails.init(billingAddress: billingAddress, email: "email@email.com")!
        XCTAssertEqual(billingDetails.name, "Name")
        XCTAssertEqual(billingDetails.address?.line1, "Line 1")
        XCTAssertEqual(billingDetails.address?.line2, "Line 2")
        XCTAssertEqual(billingDetails.address?.city, "City")
        XCTAssertEqual(billingDetails.address?.state, "State")
        XCTAssertEqual(billingDetails.address?.country, "Country")
        XCTAssertEqual(billingDetails.email, "email@email.com")
    }
}
