//
//  DocumentWarmupViewSnapshotTest.swift
//  StripeIdentity
//
//  Created by Chen Cen on 11/7/23.
//

@_spi(STP) import StripeCore
import StripeCoreTestUtils
@testable import StripeIdentity
@_spi(STP) import StripeUICore
class DocumentWarmupViewSnapshotTest: STPSnapshotTestCase {
    func testDocumentWarmupView() {
        let view = DocumentWarmupView(
            staticContent:
                    .init(
                        body: "unused body",
                        buttonText: "continue",
                        idDocumentTypeAllowlist: [
                            "passport": "Passport",
                            "driving_license": "Driver's license",
                            "id_card": "Identity card",
                        ],
                        title: "unused title"
                    )
        )
        view.autosizeHeight(width: SnapshotTestMockData.mockDeviceWidth)
        STPSnapshotVerifyView(view, file: #filePath, line: #line)
    }

}
