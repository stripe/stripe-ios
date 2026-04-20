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
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: selection, cardArtEnabled: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_success")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, false)
    }

    func testLogCSConfirmedSavedPMSuccess_savedPMWithCardArt() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCardWithCardArt())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: selection, cardArtEnabled: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_success")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, true)
    }

    func testLogCSConfirmedSavedPMSuccess_savedPMWithCardArt_disabled() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCardWithCardArt())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(paymentOptionSelection: selection, cardArtEnabled: false)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_success")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, false)
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
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection, cardArtEnabled: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, false)
    }

    func testLogCSConfirmedSavedPMFailure_savedPMWithCardArt() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCardWithCardArt())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection, cardArtEnabled: true)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, true)
    }

    func testLogCSConfirmedSavedPMFailure_savedPMWithCardArt_disabled() {
        let selection = CustomerSheet.PaymentOptionSelection.paymentMethod(._testCardWithCardArt())
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection, cardArtEnabled: false)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "card")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["has_card_art"] as? Bool, false)
    }

    func testLogCSConfirmedSavedPMFailure_applePay() {
        let selection = CustomerSheet.PaymentOptionSelection.applePay()
        analyticsClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(paymentOptionSelection: selection)
        XCTAssertEqual(analyticsClient._testLogHistory.last!["event"] as? String, "cs_select_payment_method_screen_confirmed_savedpm_failure")
        XCTAssertEqual(analyticsClient._testLogHistory.last!["payment_method_type"] as? String, "apple_pay")
        XCTAssertNil(analyticsClient._testLogHistory.last!["has_card_art"])
    }
}
