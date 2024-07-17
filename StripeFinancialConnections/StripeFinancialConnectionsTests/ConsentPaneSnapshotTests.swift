//
//  ConsentPaneSnapshotTests.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-07-04.
//

import UIKit
import XCTest

@_spi(STP) import StripeCoreTestUtils
@testable import StripeFinancialConnections

class ConsentPaneSnapshotTests: STPSnapshotTestCase {
    private var financialConnectionsSheet: FinancialConnectionsSheet!

    override func setUp() {
        super.setUp()

        self.financialConnectionsSheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: "clientSecret",
            returnURL: "returnURL"
        )
    }

    override func tearDown() {
        super.tearDown()
        financialConnectionsSheet = nil
    }

    func testConsentPane() {
        presentAndLoadFinancialConnectionsSheet()

        let navigationController = financialConnectionsSheet.hostController!.navigationController
        verify(navigationController.topViewController!.view)
    }

    // MARK: Helpers

    private func presentAndLoadFinancialConnectionsSheet() {
        FCStubbedBackend.stubSynchronize()
        FCStubbedBackend.stubImages()

        let hostController = UIViewController()
        financialConnectionsSheet.present(from: hostController, completion: { _ in })

        let navigationController = financialConnectionsSheet.hostController!.navigationController
        let loadingExpectation = XCTestExpectation(description: "Loading completed")

        // The Financial Connections sheet usually takes anywhere between 50ms-200ms (but once in a while 2-3 seconds).
        // to present with the expected content. When the sheet is presented, it initially shows a loading screen,
        // and when it is done loading, the loading screen is replaced with the expected content.
        // Therefore, the following code polls every 50 milliseconds to check if the ConsentViewController
        // is present. We then wait 0.5s to let the images load from stubs.
        DispatchQueue.global(qos: .background).async {
            for _ in 0..<10 {
                DispatchQueue.main.sync {
                    navigationController.view.layoutIfNeeded()
                    if (navigationController.topViewController as? ConsentViewController) != nil {

                        // Wait 0.5s for the stubbed images to load.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            loadingExpectation.fulfill()
                        }
                        return
                    }
                }

                usleep(50000) // 50ms
            }
        }

        wait(for: [loadingExpectation], timeout: 10.0)
    }

    private func verify(
        _ view: UIView,
        identifier: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        self.STPSnapshotVerifyView(
            view,
            identifier: identifier,
            file: file,
            line: line
        )
    }
}
