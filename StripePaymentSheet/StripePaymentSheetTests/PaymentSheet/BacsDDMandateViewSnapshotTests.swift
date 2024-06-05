//
//  BacsDDMandateViewSnapshotTests.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 9/8/23.
//

import StripeCoreTestUtils
@_spi(STP)@testable import StripePaymentSheet
@_spi(STP)@testable import StripePaymentsTestUtils
import SwiftUI
import UIKit

@MainActor
class BacsDDMandateViewSnapshotTests: STPSnapshotTestCase {

    func testBacsDDMandateView() {
        let bacsView = BacsDDMandateView(email: "j.diaz@example.com", name: "Jane Diaz", sortCode: "10-88-00", accountNumber: "00012345", confirmAction: {}, cancelAction: {})
        let vc = UIHostingController(rootView: bacsView)

        // Need to host the SwiftUI view in a window for iOSSnapshotTestCase to work:
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 428, height: 926))
        window.rootViewController = vc
        window.makeKeyAndVisible()

        // Shadow rendering isn't deterministic enough, give a slightly larger perPixelTolerance
        STPSnapshotVerifyView(vc.view, identifier: nil, perPixelTolerance: 0.04, file: #filePath, line: #line)
    }
}
