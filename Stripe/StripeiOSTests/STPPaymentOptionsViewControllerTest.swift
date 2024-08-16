//
//  STPPaymentOptionsViewControllerTest.swift
//  StripeiOS Tests
//
//  Created by Brian Dorfman on 10/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

import OCMock

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPPaymentOptionsViewControllerTest: XCTestCase {
    class MockSTPPaymentOptionsViewControllerDelegate: NSObject,
        STPPaymentOptionsViewControllerDelegate
    {
        var didFail = false
        func paymentOptionsViewController(
            _ paymentOptionsViewController: STPPaymentOptionsViewController,
            didFailToLoadWithError error: Error
        ) {
            didFail = true
        }

        var didFinish = false
        func paymentOptionsViewControllerDidFinish(
            _ paymentOptionsViewController: STPPaymentOptionsViewController
        ) {
            didFinish = true
        }

        var didCancel = false
        func paymentOptionsViewControllerDidCancel(
            _ paymentOptionsViewController: STPPaymentOptionsViewController
        ) {
            didCancel = true
        }

        var didSelect = false
        func paymentOptionsViewController(
            _ paymentOptionsViewController: STPPaymentOptionsViewController,
            didSelect paymentOption: STPPaymentOption
        ) {
            didSelect = true
        }
    }

    func buildViewController(
        with customer: STPCustomer,
        paymentMethods: [STPPaymentMethod],
        configuration config: STPPaymentConfiguration,
        delegate: STPPaymentOptionsViewControllerDelegate
    ) -> STPPaymentOptionsViewController {
        let mockCustomerContext = Testing_StaticCustomerContext(
            customer: customer,
            paymentMethods: paymentMethods
        )
        return buildViewController(
            with: mockCustomerContext,
            configuration: config,
            delegate: delegate
        )
    }

    func buildViewController(
        with customerContext: STPCustomerContext,
        configuration config: STPPaymentConfiguration,
        delegate: STPPaymentOptionsViewControllerDelegate
    ) -> STPPaymentOptionsViewController {
        let theme = STPTheme.defaultTheme
        let vc = STPPaymentOptionsViewController(
            configuration: config,
            theme: theme,
            customerContext: customerContext,
            delegate: delegate
        )
        let didLoadExpectation = expectation(description: "VC did load")
        vc.loadingPromise?.onSuccess({ (_) in
            didLoadExpectation.fulfill()
        })

        wait(for: [didLoadExpectation], timeout: 2)

        return vc
    }

    /// When the customer has no sources, and card is the sole available payment
    /// method, STPAddCardViewController should be shown.
    func testInitWithNoSourcesAndConfigWithUseSourcesOffAndCardAvailable() {
        let customer = STPFixtures.customerWithNoSources()
        let config = STPPaymentConfiguration()
        config.applePayEnabled = false
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: [],
            configuration: config,
            delegate: delegate
        )
        XCTAssertTrue((sut.internalViewController is STPAddCardViewController))
    }

    /// When the customer has a single card token source and the available payment methods
    /// are card and apple pay, STPPaymentOptionsInternalVC should be shown.
    func testInitWithSingleCardTokenSourceAndCardAvailable() {
        let customer = STPFixtures.customerWithSingleCardTokenSource()
        let paymentMethods = [STPFixtures.paymentMethod()]
        let config = STPPaymentConfiguration()
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: paymentMethods.compactMap { $0 },
            configuration: config,
            delegate: delegate
        )
        XCTAssertTrue((sut.internalViewController is STPPaymentOptionsInternalViewController))
    }

    /// When the customer has a single card source source and the available payment methods
    /// are card only, STPPaymentOptionsInternalVC should be shown.
    func testInitWithSingleCardSourceSourceAndCardAvailable() {
        let customer = STPFixtures.customerWithSingleCardSourceSource()
        let paymentMethods = [STPFixtures.paymentMethod()]
        let config = STPPaymentConfiguration()
        config.applePayEnabled = false
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: paymentMethods.compactMap { $0 },
            configuration: config,
            delegate: delegate
        )
        XCTAssertTrue((sut.internalViewController is STPPaymentOptionsInternalViewController))
    }

    /// Tapping cancel in an internal AddCard view controller should result in a call to
    /// didCancel:
    func testAddCardCancelForwardsToDelegate() {
        let customer = STPFixtures.customerWithNoSources()
        let config = STPPaymentConfiguration()
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: [],
            configuration: config,
            delegate: delegate
        )
        XCTAssertTrue((sut.internalViewController is STPAddCardViewController))
        let cancelButton = sut.internalViewController?.navigationItem.leftBarButtonItem
        _ = cancelButton?.target?.perform(cancelButton?.action, with: cancelButton)

        XCTAssertTrue(delegate.didCancel)
    }

    /// Tapping cancel in an internal PaymentOptionsInternal view controller should
    /// result in a call to didCancel:
    func testInternalCancelForwardsToDelegate() {
        let customer = STPFixtures.customerWithSingleCardTokenSource()
        let paymentMethods = [STPFixtures.paymentMethod()]
        let config = STPPaymentConfiguration()
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: paymentMethods.compactMap { $0 },
            configuration: config,
            delegate: delegate
        )
        XCTAssertTrue((sut.internalViewController is STPPaymentOptionsInternalViewController))
        let cancelButton = sut.internalViewController?.navigationItem.leftBarButtonItem
        _ = cancelButton?.target?.perform(cancelButton?.action, with: cancelButton)

        XCTAssertTrue(delegate.didCancel)
    }

    /// When an AddCard view controller creates a card payment method, it should be attached to the
    /// customer and the correct delegate methods should be called.
    func testAddCardAttachesToCustomerAndFinishes() {
        let config = STPPaymentConfiguration()
        let customer = STPFixtures.customerWithNoSources()
        let mockCustomerContext = Testing_StaticCustomerContext(
            customer: customer,
            paymentMethods: []
        )
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: mockCustomerContext,
            configuration: config,
            delegate: delegate
        )
        XCTAssertNotNil(sut.view)
        XCTAssertTrue((sut.internalViewController is STPAddCardViewController))

        let internalVC = sut.internalViewController as? STPAddCardViewController
        let exp = expectation(description: "completion")
        let expectedPaymentMethod = STPFixtures.paymentMethod()
        internalVC?.delegate?.addCardViewController(
            internalVC!,
            didCreatePaymentMethod: expectedPaymentMethod
        ) { error in
            XCTAssertNil(error)
            exp.fulfill()
        }

        let _: ((Any?) -> Bool)? = { obj in
            let paymentMethod = obj as? STPPaymentMethod
            return paymentMethod?.stripeId == expectedPaymentMethod.stripeId
        }
        XCTAssertTrue(mockCustomerContext.didAttach)
        XCTAssertTrue(delegate.didSelect)
        XCTAssertTrue(delegate.didFinish)
        waitForExpectations(timeout: 2, handler: nil)
    }

    // Tests for race condition where the promise for fetching payment methods
    // finishes in the context of intializing the sut, and `addCardViewControllerFooterView`
    // is set directly after init, while internalViewController is `STPAddCardViewController`
    func testSetAfterInit_addCardViewControllerFooterView_STPAddCardViewController() {
        let customer = STPFixtures.customerWithNoSources()
        let config = STPPaymentConfiguration()
        config.applePayEnabled = false
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: [],
            configuration: config,
            delegate: delegate
        )
        sut.addCardViewControllerFooterView = UIView()
        guard let payMethodsInternal = sut.internalViewController as? STPAddCardViewController else {
            XCTFail()
            return
        }
        XCTAssertNotNil(payMethodsInternal.customFooterView)
    }

    // Tests for race condition where the promise for fetching payment methods
    // finishes in the context of intializing the sut, and the `paymentOptionsViewControllerFooterView`
    // is set directly after init, while internalViewController is `STPPaymentOptionsInternalViewController`
    func testSetAfterInit_paymentOptionsViewControllerFooterView_STPPaymentOptionsInternalViewController() {
        let customer = STPFixtures.customerWithSingleCardTokenSource()
        let paymentMethods = [STPFixtures.paymentMethod()]
        let config = STPPaymentConfiguration()
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: paymentMethods.compactMap { $0 },
            configuration: config,
            delegate: delegate
        )
        sut.paymentOptionsViewControllerFooterView = UIView()
        guard let payMethodsInternal = sut.internalViewController as? STPPaymentOptionsInternalViewController else {
            XCTFail()
            return
        }
#if compiler(>=5.7)
        XCTAssertNotNil(payMethodsInternal.customFooterView)
#endif
    }

    // Tests for race condition where the promise for fetching payment methods
    // finishes in the context of init the sut, and the `addCardViewControllerFooterView`
    // is set directly after init, while internalViewController is `STPPaymentOptionsInternalViewController`
    func testSetAfterInit_addCardViewControllerFooterView_STPPaymentOptionsInternalViewController() {
        let customer = STPFixtures.customerWithSingleCardTokenSource()
        let paymentMethods = [STPFixtures.paymentMethod()]
        let config = STPPaymentConfiguration()
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: paymentMethods.compactMap { $0 },
            configuration: config,
            delegate: delegate
        )
        sut.addCardViewControllerFooterView = UIView()
        guard let payMethodsInternal = sut.internalViewController as? STPPaymentOptionsInternalViewController else {
            XCTFail()
            return
        }
#if compiler(>=5.7)
        XCTAssertNotNil(payMethodsInternal.addCardViewControllerCustomFooterView)
#endif
    }

    // Tests for race condition where the promise for fetching payment methods
    // finishes in the context of init the sut, and the `prefilledInformation`
    // is set directly after init, while internalViewController is `STPPaymentOptionsInternalViewController`
    func testSetAfterInit_prefilledInformation_STPPaymentOptionsInternalViewController() {
        let customer = STPFixtures.customerWithSingleCardTokenSource()
        let paymentMethods = [STPFixtures.paymentMethod()]
        let config = STPPaymentConfiguration()
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: paymentMethods.compactMap { $0 },
            configuration: config,
            delegate: delegate
        )
        let userInformation = STPUserInformation()
        let address = STPAddress()
        address.name = "John Doe"
        address.line1 = "123 Main"
        address.city = "Seattle"
        address.state = "Washington"
        address.postalCode = "98104"
        address.phone = "2065551234"
        userInformation.billingAddress = address
        sut.prefilledInformation = userInformation
        guard let payMethodsInternal = sut.internalViewController as? STPPaymentOptionsInternalViewController else {
            XCTFail()
            return
        }
#if compiler(>=5.7)
        XCTAssertNotNil(payMethodsInternal.prefilledInformation)
#endif
    }

    // Tests for race condition where the promise for fetching payment methods
    // finishes in the context of init the sut, and the `prefilledInformation`
    // is set directly after init, while internalViewController is `STPAddCardViewController`
    func testSetAfterInit_prefilledInformation_STPAddCardViewController() {
        let customer = STPFixtures.customerWithNoSources()
        let config = STPPaymentConfiguration()
        config.applePayEnabled = false
        let delegate = MockSTPPaymentOptionsViewControllerDelegate()
        let sut = buildViewController(
            with: customer,
            paymentMethods: [],
            configuration: config,
            delegate: delegate
        )
        let userInformation = STPUserInformation()
        let address = STPAddress()
        address.name = "John Doe"
        address.line1 = "123 Main"
        address.city = "Seattle"
        address.state = "Washington"
        address.postalCode = "98104"
        address.phone = "2065551234"
        userInformation.billingAddress = address
        sut.prefilledInformation = userInformation
        guard let payMethodsInternal = sut.internalViewController as? STPAddCardViewController else {
            XCTFail()
            return
        }
        XCTAssertNotNil(payMethodsInternal.prefilledInformation)
    }
}
