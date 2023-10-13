//
//  PaymentSheet+DeferredAPITest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 10/11/23.
//

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripeCoreTestUtils
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore
import XCTest

final class PaymentSheet_DeferredAPITest: XCTestCase {
    let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)

    lazy var configuration: PaymentSheet.Configuration = {
        var config = PaymentSheet.Configuration()
        config.apiClient = apiClient
        config.allowsDelayedPaymentMethods = true
        config.shippingDetails = {
            return .init(
                address: .init(
                    country: "US",
                    line1: "Line 1"
                ),
                name: "Jane Doe",
                phone: "5551234567"
            )
        }
        return config
    }()

    // MARK: setParamsForDashboardApp tests
    func testSetParamsForDashboardApp_saved() {
        let examplePaymentMethodParams = STPPaymentMethodParams(card: STPFixtures.paymentMethodCardParams(), billingDetails: nil, metadata: nil)
        let paymentOptions = STPConfirmPaymentMethodOptions()
        let examplePaymentMethod = STPFixtures.paymentMethod()
        var configurationWithCustomer = configuration
        configurationWithCustomer.customer = .init(id: "id", ephemeralKeySecret: "ek")
        let params = PaymentSheet.setParamsForDashboardApp(confirmType: .new(params: examplePaymentMethodParams,
                                                                             paymentOptions: paymentOptions,
                                                                             paymentMethod: examplePaymentMethod,
                                                                             shouldSave: true),
                                                           paymentIntentParams: .init(),
                                                           paymentIntent: STPFixtures.makePaymentIntent(),
                                                           configuration: configurationWithCustomer)

        // moto should be set to true and sfu = off_session
        XCTAssertTrue(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["moto"] as? Bool ?? false)
        XCTAssertEqual(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["setup_future_usage"] as? String, "off_session")
    }

    func testSetParamsForDashboardApp_new() {
        let params = PaymentSheet.setParamsForDashboardApp(confirmType: .saved(createValidSavedPaymentMethod()),
                                                           paymentIntentParams: .init(),
                                                           paymentIntent: STPFixtures.makePaymentIntent(),
                                                           configuration: configuration)

        // moto should be set to true
        XCTAssertTrue(params.paymentMethodOptions?.cardOptions?.additionalAPIParameters["moto"] as? Bool ?? false)
    }

    // MARK: Helpers
    func createValidSavedPaymentMethod() -> STPPaymentMethod {
        var validSavedPM: STPPaymentMethod?
        let createPMExpectation = expectation(description: "Create PM")
        apiClient.createPaymentMethod(with: ._testValidCardValue()) { paymentMethod, error in
            guard let paymentMethod = paymentMethod else {
                XCTFail(String(describing: error))
                return
            }
            validSavedPM = paymentMethod
            createPMExpectation.fulfill()
        }
        waitForExpectations(timeout: 10)
        return validSavedPM!
    }
}
