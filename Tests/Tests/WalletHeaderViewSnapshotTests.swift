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

    struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
    }

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

        headerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(headerView, identifier: "Logged in")
    }
    
    // Tests UI elements that adapt their color based on the `PaymentSheet.Appearance`
    @available(iOS 13.0, *)
    func testAdaptiveElements() {
        var darkMode = false
        
        var appearance = PaymentSheet.Appearance()
        appearance.color.background = UIColor.init(dynamicProvider: { _ in
            if darkMode {
                return .black
            }
            
            return .white
        })

        appearance.shape.cornerRadius = 0
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

        headerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        verify(headerView, identifier: "Logged in")

        headerView.showsCardPaymentMessage = true
        verify(headerView, identifier: "Card only")
    }
    
    func testCustomFont() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.regular = try XCTUnwrap(UIFont(name: "Arial-ItalicMT", size: 12.0))
        
        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        headerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
        )
        
        verify(headerView)
    }
    
    func testCustomFontScales() throws {
        var appearance = PaymentSheet.Appearance.default
        appearance.font.regular = try XCTUnwrap(UIFont(name: "Arial-ItalicMT", size: 12.0))
        appearance.font.sizeScaleFactor = 1.25

        let headerView = PaymentSheetViewController.WalletHeaderView(
            options: [.applePay, .link],
            appearance: appearance,
            delegate: nil
        )

        headerView.linkAccount = LinkAccountStub(
            email: "customer@example.com",
            redactedPhoneNumber: nil,
            isRegistered: true
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
        FBSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}
