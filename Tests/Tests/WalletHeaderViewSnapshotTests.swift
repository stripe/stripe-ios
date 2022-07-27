//
//  WalletHeaderViewSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 12/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import FBSnapshotTestCase
import StripeCoreTestUtils

@testable @_spi(STP) import Stripe

class WalletHeaderViewSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }

    func testApplePayButton() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            delegate: nil
        )
        verify(headerView)
    }

    func testLinkButton() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .link,
            delegate: nil
        )
        verify(headerView)
    }
    
    // Tests UI elements that adapt their color based on the `PaymentSheet.Appearance`
    @available(iOS 13.0, *)
    func testAdaptiveElements() {
        var darkMode = false
        
        var appearance = PaymentSheet.Appearance()
        appearance.colors.background = UIColor.init(dynamicProvider: { _ in
            if darkMode {
                return .black
            }
            
            return .white
        })

        appearance.cornerRadius = 0
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: .applePay,
            appearance: appearance,
            delegate: nil
        )
        
        verify(headerView, identifier: "Light")
        
        darkMode = true
        headerView.traitCollectionDidChange(nil)
        
        verify(headerView, identifier: "Dark")
    }

    func testAllButtons() {
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            delegate: nil
        )
        verify(headerView)

        headerView.showsCardPaymentMessage = true
        verify(headerView, identifier: "Card only")
    }
    
    func testCustomFont() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        verify(headerView)
    }
    
    func testCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.base = try XCTUnwrap(UIFont(name: "AmericanTypewriter", size: 12.0))
        appearance.font.sizeScaleFactor = 1.25

        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        verify(headerView)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 300)
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

private extension WalletHeaderViewSnapshotTests {
    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let isLoggedIn: Bool
    }

    func makeLinkAccountStub() -> LinkAccountStub {
        return LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: "+1********55",
            isRegistered: true,
            isLoggedIn: true
        )
    }
}
