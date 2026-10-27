//
//  LinkPaymentMethodPickerSnapshotTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
import UIKit

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI
@testable@_spi(STP) import StripeUICore

// @iOS26
class LinkPaymentMethodPickerSnapshotTests: STPSnapshotTestCase {

    override class func setUp() {
        if #available(iOS 26, *) {
            var configuration = PaymentSheet.Configuration()
            configuration.appearance.applyLiquidGlass()
            LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        }
    }

    func testNormal() {
        let mockDataSource = MockDataSource()

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker, identifier: "First Option")

        mockDataSource.selectedIndex = 1
        picker.reloadData()
        verify(picker, identifier: "Second Option")
    }

    func testExpanded() {
        let mockDataSource = MockDataSource()

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()
        picker.setExpanded(true, animated: false)

        verify(picker)
    }

    func testUnsupportedBankAccount() {
        let paymentMethods = LinkStubs.paymentMethods()
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.set(paymentMethod: paymentMethods[LinkStubs.PaymentMethodIndices.bankAccount], supported: false)

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.supportedPaymentMethodTypes = [ParsedEnum(.card)]
        picker.layoutSubviews()
        picker.setExpanded(true, animated: false)

        verify(picker)
    }

    func testUnsupportedSelectedNotCollapsed() {
        let paymentMethods = Array(LinkStubs.paymentMethods()[0..<1])
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.set(paymentMethod: paymentMethods.first!, supported: false)

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.setExpanded(true, animated: false)
        picker.layoutSubviews()

        verify(picker)
    }

    func testFirstOptionUnsupported() {
        let paymentMethods = LinkStubs.paymentMethods()
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.set(paymentMethod: paymentMethods.first!, supported: false)
        let picker = LinkPaymentMethodPicker()
        mockDataSource.selectedIndex = 1
        picker.dataSource = mockDataSource
        picker.setExpanded(true, animated: false)
        picker.layoutSubviews()

        verify(picker)
    }

    func testEmpty() {
        let mockDataSource = MockDataSource(paymentMethods: [])

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker)
    }

    func testLongEmail() {
        let mockDataSource = MockDataSource(
            paymentMethods: [],
            email: "thisemailislong@example.com"
        )

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker)
    }

    func testGenericPaymentMethodWithDisplayMetadata() {
        let paymentMethods = LinkStubs.paymentMethods()
        let mockDataSource = MockDataSource(paymentMethods: paymentMethods)
        mockDataSource.selectedIndex = LinkStubs.PaymentMethodIndices.genericWithDisplay

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()
        picker.setExpanded(true, animated: false)

        verify(picker)
    }

    func testRemoteIcons() {
        // Given a download manager with cached card and bank account icons
        let cardIconURL = URL(string: "https://b.stripecdn.com/card-icon.png")!
        let bankIconURL = URL(string: "https://b.stripecdn.com/bank-icon.png")!
        let uncachedIconURL = URL(string: "https://b.stripecdn.com/uncached-icon.png")!
        let urlSessionConfig = APIStubbedTestCase.stubbedURLSessionConfig()
        urlSessionConfig.urlCache = URLCache(memoryCapacity: 5_000_000, diskCapacity: 0)
        seedURLCache(urlSessionConfig.urlCache, url: cardIconURL, image: makeImage(color: .systemRed, size: CGSize(width: 48, height: 32)))
        seedURLCache(urlSessionConfig.urlCache, url: bankIconURL, image: makeImage(color: .systemBlue, size: CGSize(width: 96, height: 96)))
        let downloadManager = DownloadManager(urlSessionConfiguration: urlSessionConfig, isTesting: true)

        // ...and a card and bank account with cached icons, and a card whose icon can't be loaded
        let paymentMethods = [
            ConsumerPaymentDetails(
                stripeID: "1",
                details: .card(card: .init(expiryYear: 30, expiryMonth: 10, brand: "visa", networks: ["visa"], last4: "4242", funding: .credit, checks: nil)),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: nil,
                display: .init(label: "Visa Credit", sublabel: "•••• 4242", icon: .init(main: cardIconURL)),
                isDefault: true
            ),
            ConsumerPaymentDetails(
                stripeID: "2",
                details: .bankAccount(bankAccount: .init(iconCode: nil, name: "Checking", last4: "6789", country: "COUNTRY_US")),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: nil,
                display: .init(label: "Checking", sublabel: "••6789", icon: .init(main: bankIconURL)),
                isDefault: false
            ),
            ConsumerPaymentDetails(
                stripeID: "3",
                details: .card(card: .init(expiryYear: 30, expiryMonth: 10, brand: "amex", networks: ["amex"], last4: "0005", funding: .credit, checks: nil)),
                billingAddress: nil,
                billingEmailAddress: nil,
                nickname: nil,
                display: .init(label: "American Express Credit", sublabel: "•••• 0005", icon: .init(main: uncachedIconURL)),
                isDefault: false
            ),
        ]

        // When each payment method is displayed
        let stackView = UIStackView(arrangedSubviews: paymentMethods.map { paymentMethod in
            let contentView = LinkPaymentMethodPicker.CellContentView(downloadManager: downloadManager)
            contentView.paymentMethod = paymentMethod
            return contentView
        })
        stackView.axis = .vertical
        stackView.spacing = 16

        // Then the card icon fills the rectangular icon area, the bank account icon fills the square icon area,
        // and the card without a loadable icon shows its local brand icon
        verify(stackView)
    }

    func testLongerEmail() {
        let mockDataSource = MockDataSource(
            paymentMethods: [],
            email: "thisemailisnotreal@examplecompany.com"
        )

        let picker = LinkPaymentMethodPicker()
        picker.dataSource = mockDataSource
        picker.layoutSubviews()

        verify(picker)
    }

    func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        view.autosizeHeight(width: 335)
        view.backgroundColor = .white
        STPSnapshotVerifyView(view, identifier: identifier, file: file, line: line)
    }

    private func seedURLCache(_ urlCache: URLCache?, url: URL, image: UIImage) {
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let cachedResponse = CachedURLResponse(response: response, data: image.pngData()!)
        urlCache?.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
    }

    private func makeImage(color: UIColor, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

}

extension LinkPaymentMethodPickerSnapshotTests {

    fileprivate final class MockDataSource: LinkPaymentMethodPickerDataSource {

        let accountEmail: String

        var selectedIndex: Int = 0

        let paymentMethods: [ConsumerPaymentDetails]

        private var supportOverrides: [String: Bool] = [:]

        init(
            paymentMethods: [ConsumerPaymentDetails] = LinkStubs.paymentMethods(),
            email: String = "test@example.com"
        ) {
            self.paymentMethods = paymentMethods
            self.accountEmail = email
        }

        func numberOfPaymentMethods(in picker: LinkPaymentMethodPicker) -> Int {
            return paymentMethods.count
        }

        func set(paymentMethod: ConsumerPaymentDetails, supported: Bool) {
            supportOverrides[paymentMethod.stripeID] = supported
        }

        func paymentPicker(
            _ picker: LinkPaymentMethodPicker,
            paymentMethodAt index: Int
        ) -> ConsumerPaymentDetails {
            return paymentMethods[index]
        }

        func isPaymentMethodSupported(_ paymentMethod: ConsumerPaymentDetails?) -> Bool {
            supportOverrides[paymentMethod?.stripeID ?? "", default: true]
        }
    }

}
