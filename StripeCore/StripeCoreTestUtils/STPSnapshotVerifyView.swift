//
//  STPSnapshotVerifyView.swift
//  StripeCoreTestUtils
//
//  Created by David Estes on 4/13/22.
//

import Foundation

import FBSnapshotTestCase

public extension FBSnapshotTestCase {
    // Calls FBSnapshotVerifyView with a default 2% per-pixel color differentiation, as M1 and Intel machines render shadows differently.
    func STPSnapshotVerifyView(_ view: UIView, identifier: String? = nil, suffixes: NSOrderedSet = FBSnapshotTestCaseDefaultSuffixes(), perPixelTolerance: CGFloat = 0.02, overallTolerance: CGFloat = 0, file: StaticString = #file, line: UInt = #line) {
        FBSnapshotVerifyView(view, identifier: identifier, suffixes: suffixes, perPixelTolerance: perPixelTolerance, overallTolerance: overallTolerance, file: file, line: line)
  }
}
