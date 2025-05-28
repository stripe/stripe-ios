//
//  WalletButtonsViewSnapshotTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import SwiftUI
import UIKit

@MainActor
class WalletButtonsViewSnapshotTests: STPSnapshotTestCase {

    @available(iOS 16.0, *)
    func testWalletButtonsView() {
        let flowController = PaymentSheet.FlowController(configuration: ._testValue_MostPermissive(), loadResult: ._testValue(paymentMethodTypes: [], savedPaymentMethods: []), analyticsHelper: ._testValue())
        let WalletButtonsView = WalletButtonsView(
            flowController: flowController,
            confirmHandler: { _ in },
            orderedWallets: [.applePay, .link]
        )
        let vc = UIHostingController(rootView: WalletButtonsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: nil, file: #filePath, line: #line)
    }
}
