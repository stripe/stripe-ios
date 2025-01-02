//
//  FinancialConnectionsPresenterTests.swift
//  StripeConnect
//
//  Created by Chris Mays on 12/18/24.
//
@_spi(PrivateBetaConnect) @_spi(DashboardOnly) @testable import StripeConnect
@testable import StripeFinancialConnections

import UIKit
import XCTest

class FinancialConnectionsPresenterTests: XCTestCase {
    
    @MainActor
    func testStandardPresent() {
        let presenter = FinancialConnectionsPresenter()
        
        let clientSecret = "client_secret"
        let connectedAccountId = "account_1234"
        let publishableKey = "pk_12"
        
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: publishableKey),
                                                        appearance: .default,
                                                        fonts: [],
                                                        fetchClientSecret: {return nil})

        let sheet = presenter.makeSheet(componentManager: componentManager, clientSecret: clientSecret, connectedAccountId: connectedAccountId, from: .init())
        
        XCTAssertEqual(sheet.apiClient.publishableKey, publishableKey)
        XCTAssertEqual(sheet.apiClient.stripeAccount, connectedAccountId)
    }
    
    @MainActor
    func testPresentWithPublicKeyOverride() {
        let clientSecret = "client_secret"
        let connectedAccountId = "account_1234"
        let ukKey = "uk_123"
        let publishableKey = "pk_12"
        
        let presenter = FinancialConnectionsPresenter()
        let componentManager = EmbeddedComponentManager(apiClient: .init(publishableKey: ukKey),
                                                        appearance: .default,
                                                        publicKeyOverride: publishableKey,
                                                        baseURLOverride: nil)
        
        let sheet = presenter.makeSheet(componentManager: componentManager, clientSecret: clientSecret, connectedAccountId: connectedAccountId, from: .init())

        
        XCTAssertEqual(sheet.apiClient.publishableKey, publishableKey)
        XCTAssertEqual(sheet.apiClient.stripeAccount, connectedAccountId)
    }
}
