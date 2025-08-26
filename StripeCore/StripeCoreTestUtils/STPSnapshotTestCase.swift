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
let TEST_DEVICE_OS_VERSION_26_0 = "26.0"

open class STPSnapshotTestCase: FBSnapshotTestCase {

    open override func setUp() {
        super.setUp()
        let deviceModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]!
        recordMode = ProcessInfo.processInfo.environment["STP_RECORD_SNAPSHOTS"] != nil
        guard (deviceModel == TEST_DEVICE_MODEL && UIDevice.current.systemVersion == TEST_DEVICE_OS_VERSION) ||
        (deviceModel == TEST_DEVICE_MODEL && UIDevice.current.systemVersion == TEST_DEVICE_OS_VERSION_26_0) else {
            continueAfterFailure = false
            XCTFail("You must run snapshot tests on \(TEST_DEVICE_MODEL) running \(TEST_DEVICE_OS_VERSION) || \(TEST_DEVICE_OS_VERSION_26_0). You are running these tests on a \(deviceModel) on \(UIDevice.current.systemVersion).")
            return
        }
    }

    private func isIOS26Environment() -> Bool {
        let isIOS26Runtime = UIDevice.current.systemVersion == TEST_DEVICE_OS_VERSION_26_0

        #if compiler(>=6.2)
        let isSwift62Compiler = true
        #else
        let isSwift62Compiler = false
        #endif

        return isIOS26Runtime && isSwift62Compiler
    }

    // Calls FBSnapshotVerifyView with a default 2% per-pixel color differentiation, as M1 and Intel machines render shadows differently.
    public func STPSnapshotVerifyView(
        _ view: UIView,
        identifier: String? = nil,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        perPixelTolerance: CGFloat = 0.02,
        overallTolerance: CGFloat = 0.01,
        autoSizingHeightForWidth: CGFloat? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Process the identifier for iOS 26 environment
        let processedIdentifier: String?
        if let baseIdentifier = identifier {
            processedIdentifier = isIOS26Environment() ? "\(baseIdentifier)_iOS26" : baseIdentifier
        } else {
            processedIdentifier = isIOS26Environment() ? "iOS26" : nil
        }

        if let autoSizingHeightForWidth {
            view.autosizeHeight(width: autoSizingHeightForWidth)
        }
        if view.hasAmbiguousLayout {
            XCTFail("Snapshot test failed: \(view.debugDescription) has ambiguous layout. \nHorizontal: \(view.constraintsAffectingLayout(for: .horizontal)) \nVertical: \(view.constraintsAffectingLayout(for: .vertical))", file: file, line: line)
        }
        FBSnapshotVerifyView(
            view,
            identifier: processedIdentifier,
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
