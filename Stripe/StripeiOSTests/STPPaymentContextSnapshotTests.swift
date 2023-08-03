//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
import Foundation
import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
//
//  STPPaymentContextSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ben Guo on 12/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCaseCore
import OCMock

class STPPaymentContextSnapshotTests: FBSnapshotTestCase {
    var customerContext: STPCustomerContext?
    var config: STPPaymentConfiguration?
    var hostViewController: UINavigationController?
    var paymentContext: STPPaymentContext?

    func setUp() {
        super.setUp()
        let config = STPFixtures.paymentConfiguration()
        config?.companyName = "Test Company"
        config?.requiredBillingAddressFields = STPBillingAddressFieldsFull
        config?.shippingType = STPShippingType.shipping
        self.config = config
        var customerContext: STPCustomerContext?
        if #available(iOS 13.0, *) {
            customerContext = Testing_StaticCustomerContext_Objc.init(customer: STPFixtures.customerWithCardTokenAndSourceSources(), paymentMethods: [STPFixtures.paymentMethod(), STPFixtures.paymentMethod()])
        } else {
            customerContext = STPMocks.staticCustomerContext(with: STPFixtures.customerWithCardTokenAndSourceSources(), paymentMethods: [STPFixtures.paymentMethod(), STPFixtures.paymentMethod()])
        }
        self.customerContext = customerContext

        let viewController = UIViewController()
        hostViewController = stp_navigationControllerForSnapshotTest(withRootVC: viewController)

        //    self.recordMode = YES;
    }

    func buildPaymentContext() {
        let context = STPPaymentContext(customerContext: customerContext)
        context.hostViewController = hostViewController
        context.configuration.requiredShippingAddressFields = Set<AnyHashable>([STPContactField.emailAddress])
        paymentContext = context
    }

    func testPushPaymentOptionsSmallTitle() {
        if #available(iOS 12.0, *) {
            buildPaymentContext()

            hostViewController?.navigationBar.prefersLargeTitles = false
            paymentContext?.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.automatic
            paymentContext?.pushPaymentOptionsViewController()
            let view = stp_preparedAndSizedViewForSnapshotTest(from: hostViewController)
            STPSnapshotVerifyView(view, nil)
        }
    }

    // This test renders at a slightly larger size half the time.
    // We're deprecating Basic Integration soon, and we've spent enough time on this,
    // so these tests are being disabled for now.
    //- (void)testPushPaymentOptionsLargeTitle {
    //    if (@available(iOS 12.0, *)) {
    //        [self buildPaymentContext];
    //
    //        self.hostViewController.navigationBar.prefersLargeTitles = YES;
    //        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    //        [self.paymentContext pushPaymentOptionsViewController];
    //        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
    //        STPSnapshotVerifyView(view, nil);
    //    }
    //}

    func testPushShippingAddressSmallTitle() {
        if #available(iOS 12.0, *) {
            buildPaymentContext()

            hostViewController?.navigationBar.prefersLargeTitles = false
            paymentContext?.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.automatic
            paymentContext?.pushShippingViewController()
            let view = stp_preparedAndSizedViewForSnapshotTest(from: hostViewController)
            STPSnapshotVerifyView(view, nil)
        }
    }
    // This test renders at a slightly larger size half the time.
    // We're deprecating Basic Integration soon, and we've spent enough time on this,
    // so these tests are being disabled for now.
    //- (void)testPushShippingAddressLargeTitle {
    //    if (@available(iOS 12.0, *)) {
    //        [self buildPaymentContext];
    //
    //        self.hostViewController.navigationBar.prefersLargeTitles = YES;
    //        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    //        [self.paymentContext pushShippingViewController];
    //        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
    //        STPSnapshotVerifyView(view, nil);
    //    }
    //}
}
