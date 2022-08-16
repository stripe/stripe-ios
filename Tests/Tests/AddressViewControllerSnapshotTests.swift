//
//  AddressViewControllerSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 6/15/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import FBSnapshotTestCase
@_spi(STP) @testable import Stripe
@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripeUICore

class AddressViewControllerSnapshotTests: FBSnapshotTestCase {
    private let addressSpecProvider: AddressSpecProvider = {
        let specProvider = AddressSpecProvider()
        specProvider.addressSpecs = [
            "US": AddressSpec(format: "NOACSZ", require: "ACSZ", cityNameType: .city, stateNameType: .state, zip: "", zipNameType: .zip),
        ]
        return specProvider
    }()
    var configuration: AddressViewController.Configuration {
        var config = AddressViewController.Configuration()
        config.apiClient = .init(publishableKey: "pk_test_1234")
        return config
    }
    
    override func setUp() {
        super.setUp()
//        self.recordMode = true
    }
    
    func testShippingAddressViewController() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        let vc = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let navVC = UINavigationController(rootViewController: vc)
        testWindow.rootViewController = navVC
        verify(navVC.view)
    }
    
    @available(iOS 13.0, *)
    func testShippingAddressViewController_darkMode() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        testWindow.overrideUserInterfaceStyle = .dark
        let vc = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let navVC = UINavigationController(rootViewController: vc)
        testWindow.rootViewController = navVC
        verify(navVC.view)
    }
    
    func testShippingAddressViewController_appearance() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        var configuration = configuration
        configuration.appearance = PaymentSheetTestUtils.snapshotTestTheme
        let vc = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let navVC = UINavigationController(rootViewController: vc)
        testWindow.rootViewController = navVC
        verify(navVC.view)
    }
    
    func testShippingAddressViewController_customText() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        var configuration = configuration
        configuration.title = "Custom title"
        configuration.buttonTitle = "Custom button title"
        let vc = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let navVC = UINavigationController(rootViewController: vc)
        testWindow.rootViewController = navVC
        verify(navVC.view)
    }
        
    func testShippingAddressViewController_checkbox() {
        let testWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 500))
        testWindow.isHidden = false
        var configuration = configuration
        configuration.additionalFields.checkboxLabel = "Test checkbox text"
        configuration.defaultValues = .init(address: .init(), name: nil, phone: nil, isCheckboxSelected: true)
        let vc = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: self
        )
        let navVC = UINavigationController(rootViewController: vc)
        testWindow.rootViewController = navVC
        verify(navVC.view)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }
}

extension AddressViewControllerSnapshotTests: AddressViewControllerDelegate {
    func addressViewControllerDidFinish(_ addressViewController: AddressViewController, with address: AddressViewController.AddressDetails?) {
        // no-op
    }
}
