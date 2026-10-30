//
//  LinkInlineSignupElementSnapshotTests.swift
//  StripeiOS Tests
//

import iOSSnapshotTestCase
@_spi(InternalOnlyAPI) import StripeCoreTestUtils
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI
import XCTest

// @iOS26
class LinkInlineSignupElementSnapshotTests: STPSnapshotTestCase {

    // MARK: Checkbox mode

    func testDefaultState() {
        let sut = makeSUT()
        verify(sut)
    }

    func testDefaultState_onelink() {
        let sut = makeSUT(brand: .onelink)
        verify(sut, identifier: "onelink")
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState() {
        let sut = makeSUT(saveCheckboxChecked: true, userTypedEmailAddress: "user@example.com")
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_nonUS() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            userTypedEmailAddress: "user@example.com",
            country: "CA"
        )
        verify(sut)
    }

    func testExpandedState_nonUS_preFilled() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            userTypedEmailAddress: "user@example.com",
            country: "CA",
            preFillName: "Jane Diaz",
            preFillPhone: "+13105551234"
        )
        verify(sut)
    }

    // MARK: Default opt-in (checkboxWithDefaultOptIn mode)

    func testDefaultOptIn_unchecked() {
        let sut = makeSUT(
            saveCheckboxChecked: false,
            linkAccountEmailAddress: "user@example.com",
            preFillPhone: "+13105551234",
            allowsDefaultOptIn: true
        )
        verify(sut)
    }

    func testDefaultOptIn_fully_preFilled() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            linkAccountEmailAddress: "user@example.com",
            preFillPhone: "+13105551234",
            allowsDefaultOptIn: true
        )
        verify(sut)
    }

    func testDefaultOptIn_fully_preFilled_longEmail() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            linkAccountEmailAddress: "user_with_a_super_long_email_address@example.com",
            preFillPhone: "+13105551234",
            allowsDefaultOptIn: true
        )
        verify(sut)
    }

    func testDefaultOptIn_partially_preFilled() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            preFillPhone: "+13105551234",
            allowsDefaultOptIn: true
        )
        verify(sut)
    }

    // MARK: SignupOptIn mode

    func testSignupOptInDoesNotBreakConstraints() throws {
        // Observe the same UIKit callback used by the example app's broken-constraint alerts.
        let selector = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
        let method = try XCTUnwrap(class_getInstanceMethod(UIView.self, selector))
        let originalImplementation = method_getImplementation(method)
        typealias ConstraintCallback = @convention(c) (UIView, Selector, AnyObject, NSLayoutConstraint, NSArray) -> Void
        let originalCallback = unsafeBitCast(originalImplementation, to: ConstraintCallback.self)
        let callback: @convention(block) (UIView, AnyObject, NSLayoutConstraint, NSArray) -> Void = { view, engine, constraint, conflicts in
            XCTFail("Broken constraint: \(constraint)")
            originalCallback(view, selector, engine, constraint, conflicts)
        }
        let implementation = imp_implementationWithBlock(callback)
        method_setImplementation(method, implementation)
        defer {
            method_setImplementation(method, originalImplementation)
            imp_removeBlock(implementation)
        }

        for initiallyChecked in [false, true] {
            // Given a checkbox-only signup with a prefilled email.
            let linkAccount = PaymentSheetLinkAccount(
                email: "unknown@stripe.com",
                session: nil,
                publishableKey: nil,
                displayablePaymentDetails: nil,
                useMobileEndpoints: false,
                canSyncAttestationState: false
            )
            let viewModel = LinkInlineSignupViewModel(
                configuration: PaymentSheet.Configuration(),
                brand: .link,
                showCheckbox: true,
                accountService: MockAccountService(),
                resolvedLinkBrand: { $0?.linkBrand ?? .link },
                allowsDefaultOptIn: false,
                signupOptInFeatureEnabled: true,
                signupOptInInitialValue: initiallyChecked,
                linkAccount: linkAccount,
                country: "US"
            )

            // When the view is created and laid out.
            let view = LinkInlineSignupView(viewModel: viewModel)
            view.autosizeHeight(width: 340)

            // Then the checkbox reflects the initial value without breaking constraints.
            XCTAssertEqual(viewModel.mode, .signupOptIn)
            XCTAssertEqual(view.checkboxElement.isChecked, initiallyChecked)

            // When the model changes, the checkbox stays in sync.
            viewModel.saveCheckboxChecked = !initiallyChecked
            view.layoutIfNeeded()
            XCTAssertEqual(view.checkboxElement.isChecked, !initiallyChecked)

            // ...and tapping the checkbox updates the model without laying out unused fields.
            view.checkboxElement.isChecked.toggle()
            // This test has no app host, so invoke the handler without UIApplication event dispatch.
            view.checkboxElement.didToggleCheckbox()
            view.layoutIfNeeded()
            XCTAssertEqual(viewModel.saveCheckboxChecked, initiallyChecked)
            XCTAssertEqual(view.checkboxElement.isChecked, initiallyChecked)
        }
    }

    func testSignupOptInFeatureEnabled_unchecked() {
        let sut = makeSUT(
            linkAccountEmailAddress: "unknown@stripe.com",
            signupOptInFeatureEnabled: true
        )
        verify(sut)
    }

    func testSignupOptInFeatureEnabled_checked() {
        let sut = makeSUT(
            linkAccountEmailAddress: "unknown@stripe.com",
            signupOptInFeatureEnabled: true,
            signupOptInInitialValue: true
        )
        verify(sut)
    }

    // MARK: TextFieldsOnlyEmailFirst mode

    func testDefaultState_textFieldsOnly() {
        let sut = makeSUT(showCheckbox: false)
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_textFieldsOnly() {
        let sut = makeSUT(saveCheckboxChecked: true, userTypedEmailAddress: "user@example.com", showCheckbox: false)
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_nonUS_textFieldsOnly() {
        let sut = makeSUT(
            saveCheckboxChecked: true,
            userTypedEmailAddress: "user@example.com",
            country: "CA",
            showCheckbox: false
        )
        verify(sut)
    }

    // WARNING: If this tests fails, see go/link-signup-consent-action-log to determine if a new consent_action is needed.
    func testExpandedState_nonUS_preFilled_textFieldsOnly() {
        // In textFieldsOnly mode, the phone number should *not* be prefilled.
        let sut = makeSUT(
            saveCheckboxChecked: true,
            linkAccountEmailAddress: "user@example.com",
            country: "CA",
            preFillName: "Jane Diaz",
            preFillPhone: "+13105551234",
            showCheckbox: false
        )
        verify(sut)
    }

    // MARK: TextFieldsOnlyPhoneFirst mode

    func testDefaultState_textFieldsOnlyPhoneFirst() {
        // Phone first mode is triggered when showCheckbox is false and email is prefilled
        let sut = makeSUT(
            linkAccountEmailAddress: "user@example.com",
            showCheckbox: false
        )
        verify(sut)
    }

    func verify(
        _ element: LinkInlineSignupElement,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        element.view.autosizeHeight(width: 340)
        STPSnapshotVerifyView(element.view, identifier: identifier, file: file, line: line)
    }

}

extension LinkInlineSignupElementSnapshotTests {

    struct MockAccountService: LinkAccountServiceProtocol {
        func lookupAccount(
            withEmail email: String?,
            emailSource: StripePaymentSheet.EmailSource,
            doNotLogConsumerFunnelEvent: Bool,
            requestSurface: StripePaymentSheet.LinkRequestSurface = .default,
            completion: @escaping (Result<PaymentSheetLinkAccount?, Error>) -> Void
        ) {
            completion(
                .success(
                    PaymentSheetLinkAccount(
                        email: "user@example.com",
                        session: nil,
                        publishableKey: nil,
                        displayablePaymentDetails: nil,
                        useMobileEndpoints: false,
                        canSyncAttestationState: false,
                        requestSurface: requestSurface
                    )
                )
            )
        }

        func lookupLinkAuthToken(
            _ linkAuthTokenClientSecret: String,
            requestSurface: StripePaymentSheet.LinkRequestSurface,
            completion: @escaping (Result<StripePaymentSheet.PaymentSheetLinkAccount?, any Error>) -> Void
        ) {
            completion(
                .success(
                    PaymentSheetLinkAccount(
                        email: "user@example.com",
                        session: nil,
                        publishableKey: nil,
                        displayablePaymentDetails: nil,
                        useMobileEndpoints: false,
                        canSyncAttestationState: false,
                        requestSurface: requestSurface
                    )
                )
            )
        }

        func lookupLinkAuthIntent(
            linkAuthIntentID: String,
            requestSurface: StripePaymentSheet.LinkRequestSurface = .default,
            completion: @escaping (Result<StripePaymentSheet.LookupLinkAuthIntentResponse?, Error>) -> Void
        ) {
            let linkAccount = PaymentSheetLinkAccount(
                email: "user@example.com",
                session: nil,
                publishableKey: nil,
                displayablePaymentDetails: nil,
                useMobileEndpoints: false,
                canSyncAttestationState: false,
                requestSurface: requestSurface
            )
            let response = StripePaymentSheet.LookupLinkAuthIntentResponse(
                linkAccount: linkAccount,
                consentViewModel: nil
            )
            completion(.success(response))
        }
    }

    func makeSUT(
        saveCheckboxChecked: Bool = false,
        linkAccountEmailAddress: String? = nil,
        userTypedEmailAddress: String? = nil,
        brand: LinkBrand = .link,
        country: String = "US",
        preFillName: String? = nil,
        preFillPhone: String? = nil,
        showCheckbox: Bool = true,
        allowsDefaultOptIn: Bool = false,
        signupOptInFeatureEnabled: Bool = false,
        signupOptInInitialValue: Bool = false
    ) -> LinkInlineSignupElement {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "[Merchant]"
        configuration.defaultBillingDetails.name = preFillName
        configuration.defaultBillingDetails.phone = preFillPhone
        configuration.appearance.applyLiquidGlassIfPossible()

        var linkAccount: PaymentSheetLinkAccount?

        if let linkAccountEmailAddress {
            linkAccount = PaymentSheetLinkAccount(
                email: linkAccountEmailAddress,
                session: nil,
                publishableKey: nil,
                displayablePaymentDetails: nil,
                useMobileEndpoints: false,
                canSyncAttestationState: false
            )
        }

        let viewModel = LinkInlineSignupViewModel(
            configuration: configuration,
            brand: brand,
            showCheckbox: showCheckbox,
            accountService: MockAccountService(),
            resolvedLinkBrand: { $0?.linkBrand ?? brand },
            allowsDefaultOptIn: allowsDefaultOptIn,
            signupOptInFeatureEnabled: signupOptInFeatureEnabled,
            signupOptInInitialValue: signupOptInInitialValue,
            linkAccount: linkAccount,
            country: country
        )

        viewModel.saveCheckboxChecked = saveCheckboxChecked
        // Won't trigger the "email address prefilled" path, because it wasn't there when initialized
        if let userTypedEmailAddress {
            viewModel.emailAddress = userTypedEmailAddress
        }

        if userTypedEmailAddress != nil || linkAccountEmailAddress != nil  {
            // Wait for account to load
            let expectation = notNullExpectation(for: viewModel, keyPath: \.linkAccount)
            wait(for: [expectation], timeout: 10)
        }

        return .init(viewModel: viewModel)
    }

}
