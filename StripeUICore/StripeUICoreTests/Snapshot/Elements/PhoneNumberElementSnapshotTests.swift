//
//  PhoneNumberElementSnapshotTests.swift
//  StripeUICoreTests
//
//  Created by Cameron Sabol on 10/20/21.
//

import FBSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

class PhoneNumberElementSnapshotTests: FBSnapshotTestCase {
    
    let indexOfUS: Int? = {
        PhoneNumberElement().sortedRegionInfo.firstIndex { regionInfo in
            regionInfo.regionCode == "US"
        }
    }()
    
    func verify(_ phoneElement: PhoneNumberElement,
                file: StaticString = #filePath,
                line: UInt = #line) {
        let view = phoneElement.view
        view.autosizeHeight(width: 200)
        FBSnapshotVerifyView(view, file: file, line: line)
    }

    override func setUp() {
        super.setUp()
//        recordMode = true
    }
    
    func testEmptyUS() {
        guard let indexOfUS = indexOfUS else {
            XCTFail("Missing index of US")
            return
        }
        let phoneNumberElement = PhoneNumberElement()
        phoneNumberElement.regionElement.pickerView(phoneNumberElement.regionElement.pickerView, didSelectRow: indexOfUS, inComponent: 0)
        verify(phoneNumberElement)
    }

}
