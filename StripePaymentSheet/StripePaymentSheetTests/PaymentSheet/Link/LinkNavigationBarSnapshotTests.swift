//
//  LinkNavigationBarSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 4/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import UIKit
import XCTest

@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePayments
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet

// @iOS26
class LinkNavigationBarSnapshotTests: STPSnapshotTestCase {

    override func setUp() {

        super.setUp()

        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }

    }

    // MARK: Back Style

    func testDefault() {
        let sut = makeSUT()
        verify(sut)

        let backSut = makeSUT()
        backSut.setStyle(.back(showAdditionalButton: false))
        verify(backSut, identifier: "BackButton")
    }

    func testDefaultOnelink() {
        let sut = makeSUT(brand: .onelink)
        verify(sut, identifier: "Onelink")

        let backSut = makeSUT(brand: .onelink)
        backSut.setStyle(.back(showAdditionalButton: false))
        verify(backSut, identifier: "OnelinkBackButton")
    }

    func testTitle() {
        let sut = makeSUT(title: "Test title")
        sut.setStyle(.back(showAdditionalButton: false))
        verify(sut)
    }

    func testLongTitle() {
        let sut = makeSUT(title: "Test title that is pretty long")
        sut.setStyle(.back(showAdditionalButton: false))
        verify(sut)
    }

    func testTruncatingTitle() {
        let sut = makeSUT(title: "Test title that is pretty long and should truncate")
        sut.setStyle(.back(showAdditionalButton: false))
        verify(sut)
    }

    func testBackStyleThenTruncatingTitle() {
        let sut = LinkSheetNavigationBar(appearance: LinkUI.appearance, brand: .link)
        sut.setStyle(.back(showAdditionalButton: false))
        sut.title = "Test title that is pretty long and should wrap"
        verify(sut)
    }

    func testRightToLeft() {
        let sut = makeSUT(title: "Test title that is pretty long and should truncate")
        sut.semanticContentAttribute = .forceRightToLeft
        sut.setStyle(.back(showAdditionalButton: true))

        verify(sut)
    }

    // MARK: Close Style

    func testTitleCloseStyle() {
        let sut = makeSUT(title: "Test title")
        sut.setStyle(.close(showAdditionalButton: false))
        verify(sut)
    }

    func testLongTitleCloseStyle() {
        let sut = makeSUT(title: "Test title that is pretty long")
        sut.setStyle(.close(showAdditionalButton: false))
        verify(sut)
    }

    func testTruncatingTitleCloseStyle() {
        let sut = makeSUT(title: "Test title that is pretty long and should wrap")
        sut.setStyle(.close(showAdditionalButton: false))
        verify(sut)
    }

    func testCloseStyleThenTruncatingTitle() {
        let sut = LinkSheetNavigationBar(appearance: LinkUI.appearance, brand: .link)
        sut.setStyle(.close(showAdditionalButton: false))
        sut.title = "Test title that is pretty long and should wrap"
        verify(sut)
    }

    #if !os(visionOS)
    @MainActor
    func testNativeLogoIsLeadingAndHiddenOnBackScreens() throws {
        for brand in [LinkBrand.link, .onelink] {
            // Given a Link header hosted by UIKit's navigation bar
            let sut = makeSUT(brand: brand)
            let content = UIViewController()
            sut.systemNavigationItem = content.navigationItem
            let navigationController = UINavigationController(rootViewController: content)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 800))
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            navigationController.view.layoutIfNeeded()

            // Then the rendered logo is on the leading side, with Close on the trailing side
            let logo = try XCTUnwrap(content.navigationItem.leftBarButtonItem?.customView as? UIImageView)
            let logoFrame = logo.convert(logo.bounds, to: navigationController.view)
            XCTAssertGreaterThan(logoFrame.width, 0)
            XCTAssertLessThan(logoFrame.maxX, navigationController.view.bounds.midX)
            XCTAssertNil(content.navigationItem.titleView)
            XCTAssertEqual(content.navigationItem.rightBarButtonItem?.accessibilityIdentifier, "UIButton.Close")

            // When a title is set, branding remains separate from the centered screen title
            sut.title = "Confirm payment"
            XCTAssertEqual(content.navigationItem.title, "Confirm payment")
            XCTAssertIdentical(content.navigationItem.leftBarButtonItem?.customView, logo)

            // When navigating forward and back, the logo gives way to Back and is then restored
            sut.setStyle(.back(showAdditionalButton: false))
            XCTAssertEqual(content.navigationItem.leftBarButtonItem?.accessibilityIdentifier, "UIButton.Back")
            XCTAssertNil(content.navigationItem.titleView)
            sut.setStyle(.close(showAdditionalButton: false))
            XCTAssertIdentical(content.navigationItem.leftBarButtonItem?.customView, logo)
        }
    }
    #endif

    // MARK: Utilities

    func verify(
        _ sut: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let size = sut.systemLayoutSizeFitting(
            CGSize(width: 375, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        sut.bounds = CGRect(origin: .zero, size: size)
        STPSnapshotVerifyView(sut, identifier: identifier, file: file, line: line)
    }

}

extension LinkNavigationBarSnapshotTests {
    fileprivate struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let sessionState: PaymentSheetLinkAccount.SessionState
        let consumerSessionClientSecret: String?
        let linkSessionKey: String?
    }

    fileprivate func makeAccountStub() -> LinkAccountStub {
        return LinkAccountStub(
            email: "test@example.com",
            redactedPhoneNumber: "+1********55",
            isRegistered: true,
            sessionState: .verified,
            consumerSessionClientSecret: nil,
            linkSessionKey: nil
        )
    }

    fileprivate func makeSUT(title: String? = nil, brand: LinkBrand = .link) -> LinkSheetNavigationBar {
        let sut = LinkSheetNavigationBar(appearance: LinkUI.appearance, brand: brand)
        sut.title = title
        return sut
    }
}
