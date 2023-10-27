//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPPaymentContextSnapshotTests.m
//  StripeiOS Tests
//
//  Created by Ben Guo on 12/13/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import iOSSnapshotTestCaseCore
import StripeCoreTestUtils

class STPPaymentContextSnapshotTests: STPSnapshotTestCase {
    var customerContext: STPCustomerContext?
    var config: STPPaymentConfiguration?
    var hostViewController: UINavigationController?
    var paymentContext: STPPaymentContext?

    override func setUp() {
        super.setUp()
        let config = STPPaymentConfiguration()
        config.companyName = "Test Company"
        config.requiredBillingAddressFields = .full
        config.shippingType = .shipping
        self.config = config
        let customerContext = Testing_StaticCustomerContext_Objc.init(customer: STPFixtures.customerWithCardTokenAndSourceSources(), paymentMethods: [STPFixtures.paymentMethod(), STPFixtures.paymentMethod()])
        self.customerContext = customerContext

        let viewController = UIViewController()
        hostViewController = stp_navigationControllerForSnapshotTest(withRootVC: viewController)
    }

    func buildPaymentContext() {
        let context = STPPaymentContext(customerContext: customerContext!)
        context.hostViewController = hostViewController
        context.configuration.requiredShippingAddressFields = Set([STPContactField.emailAddress])
        paymentContext = context
    }

    func testPushPaymentOptionsSmallTitle() {
        buildPaymentContext()

        hostViewController?.navigationBar.prefersLargeTitles = false
        paymentContext?.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.automatic
        paymentContext?.pushPaymentOptionsViewController()
        let view = stp_preparedAndSizedViewForSnapshotTest(from: hostViewController)!
        STPSnapshotVerifyView(view, identifier: nil)
    }

    // This test renders at a slightly larger size half the time.
    // We're deprecating Basic Integration soon, and we've spent enough time on this,
    // so these tests are being disabled for now.
    // - (void)testPushPaymentOptionsLargeTitle {
    //        [self buildPaymentContext];
    //
    //        self.hostViewController.navigationBar.prefersLargeTitles = YES;
    //        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    //        [self.paymentContext pushPaymentOptionsViewController];
    //        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
    //        STPSnapshotVerifyView(view, nil);
    // }

    func testPushShippingAddressSmallTitle() {
        buildPaymentContext()

        hostViewController?.navigationBar.prefersLargeTitles = false
        paymentContext?.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.automatic
        paymentContext?.pushShippingViewController()
        let view = stp_preparedAndSizedViewForSnapshotTest(from: hostViewController)!
        STPSnapshotVerifyView(view, identifier: nil)
    }
    // This test renders at a slightly larger size half the time.
    // We're deprecating Basic Integration soon, and we've spent enough time on this,
    // so these tests are being disabled for now.
    // - (void)testPushShippingAddressLargeTitle {
    //        [self buildPaymentContext];
    //
    //        self.hostViewController.navigationBar.prefersLargeTitles = YES;
    //        self.paymentContext.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    //        [self.paymentContext pushShippingViewController];
    //        UIView *view = [self stp_preparedAndSizedViewForSnapshotTestFromNavigationController:self.hostViewController];
    //        STPSnapshotVerifyView(view, nil);
    // }
}
