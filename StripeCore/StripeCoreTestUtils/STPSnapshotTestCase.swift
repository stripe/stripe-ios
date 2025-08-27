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
        if deviceModel != TEST_DEVICE_MODEL || (UIDevice.current.systemVersion != TEST_DEVICE_OS_VERSION) && UIDevice.current.systemVersion != TEST_DEVICE_OS_VERSION_26_0 {
            continueAfterFailure = false
            XCTFail("You must run snapshot tests on \(TEST_DEVICE_MODEL) running \(TEST_DEVICE_OS_VERSION). You are running these tests on a \(deviceModel) on \(UIDevice.current.systemVersion).")
        }
    }

    var isIOS26: Bool {
        return UIDevice.current.systemVersion == TEST_DEVICE_OS_VERSION_26_0
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
        if let autoSizingHeightForWidth {
            view.autosizeHeight(width: autoSizingHeightForWidth)
        }
        if view.hasAmbiguousLayout {
            XCTFail("Snapshot test failed: \(view.debugDescription) has ambiguous layout. \nHorizontal: \(view.constraintsAffectingLayout(for: .horizontal)) \nVertical: \(view.constraintsAffectingLayout(for: .vertical))", file: file, line: line)
        }
        let iOS26Identifier: String? = {
            if let baseIdentifier = identifier {
                return "\(baseIdentifier)_iOS26"
            } else {
                return "iOS26"
            }
        }()
        // identifier is appended to the image filename e.g. "reference_{test name}_{identifier}"
        let identifier: String? = {
            if recordMode {
                // Record the reference image according to our specific iOS version
                // Long-term - always record the image using an identifier containing the specific ios version (eg "test_foo_iOS26"
                return isIOS26 ? iOS26Identifier : identifier
            } else {
                func hasReferenceImage(for identifier: String?) -> Bool {
                    do {
                        try referenceImageRecorded(inDirectory: "\(getReferenceImageDirectory(withDefault: nil))_64", identifier: identifier)
                        return true
                    } catch {
                        return false
                    }
                }
                if isIOS26, hasReferenceImage(for: iOS26Identifier) {
                    // If we're on iOS 26 and have a reference image specific to iOS 26, verify using that.
                    return iOS26Identifier
                } else {
                    // Otherwise, use the non-iOS-version-specific reference image
                    return identifier
                }
            }
        }()
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

public extension STPSnapshotTestCase {
    // Copy and pasted from FBSnapshotVerifyViewOrLayer and modified to return an error instead of XCTFail.
    private func _STPSnapshotVerifyViewOrLayer(
        _ viewOrLayer: AnyObject,
        identifier: String? = nil,
        suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(),
        perPixelTolerance: CGFloat = 0,
        overallTolerance: CGFloat = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let envReferenceImageDirectory = self.getReferenceImageDirectory(withDefault: nil)
        let envImageDiffDirectory = self.getImageDiffDirectory(withDefault: nil)
        var error: NSError?
        var comparisonSuccess = false

        for suffix in suffixes {
            let referenceImagesDirectory = "\(envReferenceImageDirectory)\(suffix)"
            let imageDiffDirectory = envImageDiffDirectory
            if viewOrLayer.isKind(of: UIView.self) {
                do {
                    try compareSnapshot(of: viewOrLayer as! UIView, referenceImagesDirectory: referenceImagesDirectory, imageDiffDirectory: imageDiffDirectory, identifier: identifier, perPixelTolerance: perPixelTolerance, overallTolerance: overallTolerance)
                    comparisonSuccess = true
                } catch let error1 as NSError {
                    error = error1
                    comparisonSuccess = false
                }
            } else if viewOrLayer.isKind(of: CALayer.self) {
                do {
                    try compareSnapshot(of: viewOrLayer as! CALayer, referenceImagesDirectory: referenceImagesDirectory, imageDiffDirectory: imageDiffDirectory, identifier: identifier, perPixelTolerance: perPixelTolerance, overallTolerance: overallTolerance)
                    comparisonSuccess = true
                } catch let error1 as NSError {
                    error = error1
                    comparisonSuccess = false
                }
            } else {
                assertionFailure("Only UIView and CALayer classes can be snapshotted")
            }

            assert(recordMode == false, message: "Test ran in record mode. Reference image is now saved. Disable record mode to perform an actual snapshot comparison!", file: file, line: line)

            if comparisonSuccess || recordMode {
                break
            }
        }
        return error
    }
}
