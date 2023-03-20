//
//  AutoCompleteViewControllerSnapshotTests.swift
//  PaymentSheetUITest
//
//  Created by Nick Porter on 6/7/22.
//  Copyright © 2022 stripe-ios. All rights reserved.
//

import Foundation
import FBSnapshotTestCase
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeUICore

class AutoCompleteViewControllerSnapshotTests: FBSnapshotTestCase {
    
    private var configuration: AddressViewController.Configuration {
        return AddressViewController.Configuration()
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
                                titleHighlightRanges: [NSValue(range: NSRange(location: 0, length: 6))],
                                subtitleHighlightRanges: [NSValue(range: NSRange(location: 2, length: 4))]),
        MockAddressSearchResult(title: "354 Oyster Point Blvd",
                                subtitle: "San Francisco, CA 94080 United States",
                                titleHighlightRanges: [NSValue(range: NSRange(location: 2, length: 4))],
                                subtitleHighlightRanges: [NSValue(range: NSRange(location: 4, length: 2))]),
        MockAddressSearchResult(title: "10 Boulevard",
                                subtitle: "Haussmann Paris 75009 France",
                                titleHighlightRanges: [NSValue(range: NSRange(location: 4, length: 2))],
                                subtitleHighlightRanges: [NSValue(range: NSRange(location: 0, length: 4))])
        ]

    override func setUp() {
        super.setUp()

//        self.recordMode = true
    }
    
    func testAutoCompleteViewController() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        let vc = AutoCompleteViewController(configuration: configuration,
                                            addressSpecProvider: addressSpecProvider)
        vc.results = mockSearchResults
        testWindow.rootViewController = vc
        
        verify(vc.view)
    }
    
    @available(iOS 13.0, *)
    func testAutoCompleteViewController_darkMode() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        testWindow.overrideUserInterfaceStyle = .dark
        let vc = AutoCompleteViewController(configuration: configuration,
                                            addressSpecProvider: addressSpecProvider)
        
        vc.results = mockSearchResults
        testWindow.rootViewController = vc
        
        verify(vc.view)
    }
    
    func testAutoCompleteViewController_appearance() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        
        var config = configuration
        config.appearance.colors.background = .blue
        config.appearance.colors.text = .yellow
        config.appearance.colors.textSecondary = .red
        config.appearance.colors.componentPlaceholderText = .cyan
        config.appearance.colors.componentBackground = .red
        config.appearance.colors.componentDivider = .green
        config.appearance.cornerRadius = 0.0
        config.appearance.borderWidth = 2.0
        config.appearance.font.base = UIFont(name: "AmericanTypeWriter", size: 12)!
        config.appearance.colors.primary = .red
        
        let vc = AutoCompleteViewController(configuration: config,
                                            addressSpecProvider: addressSpecProvider)
        vc.results = mockSearchResults
        testWindow.rootViewController = vc

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
