//
//  STPPaymentHandlerRefreshTests.swift
//  StripeiOSTests
//
//  Created by Nick Porter on 5/13/24.
//

import Foundation
import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import Stripe3DS2
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentHandlerRefreshTests: XCTestCase {

    func testPaymentIntentShouldHitRefreshEndpoint() {
        let shouldRefresh: [STPPaymentMethodType] = [.cashApp]

        for paymentMethodType in STPPaymentMethodType.allCases {
            let paymentMethodDict: [AnyHashable: Any] = [
                "id": "pm_test",
                "type": paymentMethodType.identifier,
            ]
            let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: [paymentMethodType.identifier],
                                                          status: .requiresAction,
                                                          paymentMethod: paymentMethodDict,
                                                          nextAction: .useStripeSDK)

            let apiClientMock = STPAPIClientMock()
            let currentAction = STPPaymentHandlerPaymentIntentActionParams.makeTestable(apiClient: apiClientMock,
                                                                                        paymentMethodTypes: [paymentMethodType.identifier],
                                                                                        paymentIntent: paymentIntent)

            let paymentHandler = STPPaymentHandler(apiClient: apiClientMock)
            paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

            let requiresRefresh = shouldRefresh.contains(paymentMethodType)
            XCTAssertEqual(apiClientMock.refreshPaymentIntentCalled, requiresRefresh,
                           "\(paymentMethodType.displayName) should \(requiresRefresh ? "" : "not ")hit the refresh endpoint when using a PaymentIntent")
            XCTAssertEqual(apiClientMock.retrievePaymentIntentCalled, !requiresRefresh,
                           "\(paymentMethodType.displayName) should \(requiresRefresh ? "" : "not ")hit the retrieve endpoint when using a PaymentIntent")
        }
    }

    func testSetupIntentShouldHitRefreshEndpoint() {
        let shouldRefresh: [STPPaymentMethodType] = [.cashApp]

        for paymentMethodType in STPPaymentMethodType.allCases {
            let paymentMethodDict: [AnyHashable: Any] = [
                "id": "pm_test",
                "type": paymentMethodType.identifier,
            ]

            let setupIntent = STPFixtures.setupIntent(paymentMethodTypes: [paymentMethodType.identifier],
                                                      status: .requiresAction,
                                                      paymentMethod: paymentMethodDict,
                                                      nextAction: .useStripeSDK)

            let apiClientMock = STPAPIClientMock()
            let currentAction = STPPaymentHandlerSetupIntentActionParams.makeTestable(apiClient: apiClientMock,
                                                                                      paymentMethodTypes: [paymentMethodType.identifier],
                                                                                      setupIntent: setupIntent)

            let paymentHandler = STPPaymentHandler(apiClient: apiClientMock)
            paymentHandler._retrieveAndCheckIntentForCurrentAction(currentAction: currentAction)

            let requiresRefresh = shouldRefresh.contains(paymentMethodType)
            XCTAssertEqual(apiClientMock.refreshSetupIntentCalled, requiresRefresh,
                           "\(paymentMethodType.displayName) should \(requiresRefresh ? "" : "not ")hit the refresh endpoint when using a SetupIntent")
            XCTAssertEqual(apiClientMock.retrieveSetupIntentCalled, !requiresRefresh,
                           "\(paymentMethodType.displayName) should \(requiresRefresh ? "" : "not ")hit the retrieve endpoint when using a SetupIntent")
        }
    }
}

// MARK: - Mocks and helpers

class STPAPIClientMock: STPAPIClient {
    var refreshPaymentIntentCalled = false
    var refreshSetupIntentCalled = false
    var retrievePaymentIntentCalled = false
    var retrieveSetupIntentCalled = false

    override func refreshPaymentIntent(withClientSecret secret: String, completion: @escaping STPPaymentIntentCompletionBlock) {
        refreshPaymentIntentCalled = true
    }

    override func refreshSetupIntent(withClientSecret secret: String, completion: @escaping STPSetupIntentCompletionBlock) {
        refreshSetupIntentCalled = true
    }

    override func retrievePaymentIntent(
        withClientSecret secret: String,
        expand: [String]?,
        completion: @escaping STPPaymentIntentCompletionBlock
    ) {
        retrievePaymentIntentCalled = true
    }

    override func retrieveSetupIntent(
        withClientSecret secret: String,
        expand: [String]?,
        completion: @escaping STPSetupIntentCompletionBlock
    ) {
        retrieveSetupIntentCalled = true
    }
}

extension STPPaymentHandlerPaymentIntentActionParams {
    static func makeTestable(apiClient: STPAPIClient,
                             paymentMethodTypes: [String],
                             paymentIntent: STPPaymentIntent) -> STPPaymentHandlerPaymentIntentActionParams {

        return .init(apiClient: apiClient,
                     authenticationContext: STPAuthenticationContextMock(),
                     threeDSCustomizationSettings: .init(),
                     paymentIntent: paymentIntent,
                     returnURL: nil) { _, _, _ in
            // no-op
        }
    }
}

extension STPPaymentHandlerSetupIntentActionParams {
    static func makeTestable(apiClient: STPAPIClient,
                             paymentMethodTypes: [String],
                             setupIntent: STPSetupIntent) -> STPPaymentHandlerSetupIntentActionParams {

        return .init(apiClient: apiClient,
                     authenticationContext: STPAuthenticationContextMock(),
                     threeDSCustomizationSettings: .init(),
                     setupIntent: setupIntent,
                     returnURL: nil) { _, _, _ in
            // no-op
        }
    }
}

class STPAuthenticationContextMock: NSObject, STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
