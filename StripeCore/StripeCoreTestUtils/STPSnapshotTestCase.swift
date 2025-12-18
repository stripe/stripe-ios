//
//  STPSnapshotTestCase.swift
//  StripeCoreTestUtils
//
//  Created by David Estes on 4/13/22.
//

#if !os(visionOS)
import Foundation
import iOSSnapshotTestCase

let TEST_DEVICE_MODEL = "iPhone13,1" // iPhone 12 mini
let TEST_DEVICE_OS_VERSION = "16.4"
let TEST_DEVICE_OS_VERSION_26_2 = "26.2"

open class STPSnapshotTestCase: FBSnapshotTestCase {

    open override func setUp() {
        super.setUp()
        let deviceModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]!
        recordMode = ProcessInfo.processInfo.environment["STP_RECORD_SNAPSHOTS"] != nil
        guard deviceModel == TEST_DEVICE_MODEL,
              [TEST_DEVICE_OS_VERSION, TEST_DEVICE_OS_VERSION_26_2].contains(UIDevice.current.systemVersion)
        else {
            continueAfterFailure = false
            XCTFail("You must run snapshot tests on \(TEST_DEVICE_MODEL) running \(TEST_DEVICE_OS_VERSION) or \(TEST_DEVICE_OS_VERSION_26_2). You are running these tests on a \(deviceModel) on \(UIDevice.current.systemVersion).")
            return
        }
    }

    var isIOS26_1: Bool {
        let isiOS26_1 = UIDevice.current.systemVersion == TEST_DEVICE_OS_VERSION_26_2
        #if compiler(>=6.2.1)
        let isXcode26_1 = true
        #else
        let isXcode26_1 = false
        Swift.assert(!isiOS26_1, "Running iOS 26 on Xcode 16 is possible but an error because iOS 26 specific code won't be compiled")
        #endif
        return isiOS26_1 && isXcode26_1
    }

    // Calls FBSnapshotVerifyView with a default 2% per-pixel color differentiation, as M1 and Intel machines render shadows differently.
    public func STPSnapshotVerifyView(
        _ view: UIView,
        identifier: String? = nil,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        perPixelTolerance: CGFloat = 0.02,
        overallTolerance: CGFloat = 0,
        autoSizingHeightForWidth: CGFloat? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Append "iOS26" to snapshot filename if testing on iOS 26
        let ios26Identifier = identifier.map { "\($0)_iOS26" } ?? "iOS26"
        let identifier = isIOS26_1 ? ios26Identifier : identifier

        if let autoSizingHeightForWidth {
            view.autosizeHeight(width: autoSizingHeightForWidth)
        }
        if view.hasAmbiguousLayout {
            XCTFail("Snapshot test failed: \(view.debugDescription) has ambiguous layout. \nHorizontal: \(view.constraintsAffectingLayout(for: .horizontal)) \nVertical: \(view.constraintsAffectingLayout(for: .vertical))", file: file, line: line)
        }
        FBSnapshotVerifyView(
            view,
            identifier: identifier,
            suffixes: suffixes,
            perPixelTolerance: perPixelTolerance,
            overallTolerance: overallTolerance,
            file: file,
            line: line
        )
    }

}
#else
import XCTest
// No-op on visionOS for now, snapshot tests not supported
open class STPSnapshotTestCase: XCTestCase {
    public func STPSnapshotVerifyView(
        _ view: UIView,
        identifier: String? = nil,
        suffixes: NSOrderedSet = NSOrderedSet(),
        perPixelTolerance: CGFloat = 0.02,
        overallTolerance: CGFloat = 0,
        autoSizingHeightForWidth: CGFloat? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Do nothing!
    }
}
#endif
