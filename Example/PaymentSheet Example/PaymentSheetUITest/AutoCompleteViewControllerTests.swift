//
//  AutoCompleteViewControllerTests.swift
//  PaymentSheetUITest
//
//  Created by Nick Porter on 6/7/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import Foundation
import FBSnapshotTestCase
@testable import Stripe
@_spi(STP) @testable import StripeUICore

class AutoCompleteViewControllerTests: FBSnapshotTestCase {
    
    private var configuration: PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePay = .init(
            merchantId: "com.foo.example", merchantCountryCode: "US")
        configuration.allowsDelayedPaymentMethods = true
        configuration.returnURL = "mockReturnUrl"
        
        return configuration
    }
    
    private let addressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "ACSZP", require: "AZ", cityNameType: .post_town, stateNameType: .state, zip: "", zipNameType: .pin)
        ]
        return specProvider
    }()
    
    private let mockSearchResults: [AddressSearchResult] = [
        MockAddressSearchResult(title: "199 Water Street",
                                subtitle: "New York, NY 10038 United States",
                                titleHighlightRanges: [],
                                subtitleHighlightRanges: []),
        MockAddressSearchResult(title: "354 Oyster Point Blvd",
                                subtitle: "San Francisco, CA 94080 United States",
                                titleHighlightRanges: [],
                                subtitleHighlightRanges: []),
        MockAddressSearchResult(title: "10 Boulevard",
                                subtitle: "Haussmann Paris 75009 France",
                                titleHighlightRanges: [],
                                subtitleHighlightRanges: [])
        ]

    override func setUp() {
        super.setUp()

//        self.recordMode = true
    }
    
    func testAutoCompleteViewController() {
        let vc = AutoCompleteViewController(configuration: configuration,
                                            addressSpecProvider: addressSpecProvider)
        vc.results = mockSearchResults
        
        verify(vc.view)
    }
    
    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view,
                             identifier: identifier,
                             suffixes: FBSnapshotTestCaseDefaultSuffixes(),
                             file: file,
                             line: line)
    }
}

private struct MockAddressSearchResult: AddressSearchResult {
    let title: String
    let subtitle: String
    let titleHighlightRanges: [NSValue]
    let subtitleHighlightRanges: [NSValue]
    
    func asAddress(completion: @escaping (PaymentSheet.Address?) -> ()) {
        completion(nil)
    }
}
