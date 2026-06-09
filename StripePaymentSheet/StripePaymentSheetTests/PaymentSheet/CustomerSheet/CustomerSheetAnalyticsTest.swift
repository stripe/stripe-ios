//
//  CustomerSheetAnalyticsTest.swift
//  StripePaymentSheetTests
//

@testable@_spi(STP) import StripeCore
@_spi(STP)@testable import StripeCoreTestUtils
@_spi(STP)@testable import StripePayments
@testable @_spi(STP) import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import XCTest

@MainActor
final class CustomerSheetAnalyticsTest: XCTestCase {
    let analyticsClient = STPTestingAnalyticsClient()

    func testLogCSConfirmedSavedPMSuccess_savedPM() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCard())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_success")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, false)
    }

    func testLogCSConfirmedSavedPMSuccess_savedPMWithCardArt() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCardWithCardArt())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_success")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, true)
    }

    func testLogCSConfirmedSavedPMSuccess_applePay() {
        let selection = CustomerSheet.PaymentOptionSelection.applePay()
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_success")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "apple_pay")
        XCTAssertNil(analyticsClient._testLogHistory.last!["has_card_art"])
    }

    func testLogCSConfirmedSavedPMFailure_savedPM() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCard())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, false)
    }

    func testLogCSConfirmedSavedPMFailure_savedPMWithCardArt() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCardWithCardArt())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, true)
    }

    func testLogCSConfirmedSavedPMFailure_applePay() {
        let selection = CustomerSheet.PaymentOptionSelection.applePay()
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "apple_pay")
        XCTAssertNil(analyticsClient._testLogHistory.last!["has_card_art"])
    }

    // MARK: - logCustomerSheetBillingAddressCompleted

    func testLogCustomerSheetBillingAddressCompleted_withAutocomplete() {
        analyticsClient.logCustomerSheetBillingAddressCompleted(
            addressCountryCode: "US",
            autoCompleteResultedSelected: true,
            editDistance: 2,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = analyticsClient._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "cs_billing_address_completed")
        let blob = last["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(blob?["address_country_code"] as? String, "US")
        XCTAssertEqual(blob?["auto_complete_result_selected"] as? Bool, true)
        XCTAssertEqual(blob?["edit_distance"] as? Int, 2)
    }

    func testLogCustomerSheetBillingAddressCompleted_withoutAutocomplete() {
        analyticsClient.logCustomerSheetBillingAddressCompleted(
            addressCountryCode: "GB",
            autoCompleteResultedSelected: false,
            editDistance: nil,
            apiClient: .init(publishableKey: "pk_test_123")
        )
        let last = analyticsClient._testLogHistory.last!
        XCTAssertEqual(last["event"] as? String, "cs_billing_address_completed")
        let blob = last["address_data_blob"] as? [String: Any?]
        XCTAssertEqual(blob?["address_country_code"] as? String, "GB")
        XCTAssertEqual(blob?["auto_complete_result_selected"] as? Bool, false)
        XCTAssertNil(blob?["edit_distance"] as? Int)
    }
}
