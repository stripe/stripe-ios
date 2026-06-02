//
//  STPSnapshotTestCase.swift
//  StripeCoreTestUtils
//
//  Created by David Estes on 4/13/22.
//

#if !os(visionOS)
import Foundation
import iOSSnapshotTestCase

open class STPSnapshotTestCase: FBSnapshotTestCase {

    open override func setUp() {
        super.setUp()
        recordMode = true
    }

    open override func getReferenceImageDirectory(withDefault dir: String?) -> String {
        return ProcessInfo.processInfo.environment["SNAPSHOT_RECORD_DIR"] ?? "/tmp/snapshot-records"
    }

    open override func record(_ issue: XCTIssue) {
        if recordMode && issue.compactDescription.contains("record mode") {
            return
        }
        super.record(issue)
    }

    var isIOS26: Bool {
        let majorVersion = UIDevice.current.systemVersion.split(separator: ".").first.flatMap { Int($0) } ?? 0
        #if compiler(>=6.2.1)
        return majorVersion >= 26
        #else
        return false
        #endif
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
        let ios26Identifier = identifier.map { "\($0)_iOS26" } ?? "iOS26"
        let identifier = isIOS26 ? ios26Identifier : identifier

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
        attachSnapshot(view, identifier: identifier)
    }

}

private extension STPSnapshotTestCase {
    func attachSnapshot(_ view: UIView, identifier: String?) {
        guard ProcessInfo.processInfo.environment["STP_DISABLE_SNAPSHOT_XCRESULT_ATTACHMENTS"] == nil else {
            return
        }

        if let url = recordedSnapshotURL(identifier: identifier) {
            let attachment = XCTAttachment(contentsOfFile: url)
            attachment.lifetime = .keepAlways
            attachment.name = snapshotAttachmentName(for: url)
            add(attachment)
        } else if let image = imageForSnapshotAttachment(view) {
            let attachment = XCTAttachment(image: image)
            attachment.lifetime = .keepAlways
            attachment.name = snapshotAttachmentName(identifier: identifier)
            add(attachment)
        }
    }

    func imageForSnapshotAttachment(_ view: UIView) -> UIImage? {
        view.layoutIfNeeded()
        guard !view.bounds.isEmpty else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = view.isOpaque
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size, format: format)
        return renderer.image { context in
            if usesDrawViewHierarchyInRect {
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            } else {
                view.layer.render(in: context.cgContext)
            }
        }
    }

    func snapshotAttachmentName(identifier: String?) -> String {
        let testName = snapshotTestMethodName
        if let identifier, !identifier.isEmpty {
            return "\(testName)_\(identifier)"
        }
        return testName
    }

    func snapshotAttachmentName(for url: URL) -> String {
        let recordDirectory = snapshotRecordDirectories
            .first { url.path.hasPrefix($0.path + "/") }
        let relativePath = recordDirectory.map {
            String(url.path.dropFirst($0.path.count + 1))
        } ?? url.lastPathComponent
        return relativePath
            .replacingOccurrences(of: "/", with: ".")
            .replacingOccurrences(of: ".png", with: "")
            .replacingOccurrences(of: #"@\d+x$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: ".", with: "_")
    }

    func recordedSnapshotURL(identifier: String?) -> URL? {
        let expectedName = snapshotFileName(identifier: identifier)
        let fileManager = FileManager.default
        var newestMatch: (url: URL, modificationDate: Date)?
        for directory in snapshotRecordDirectories where fileManager.fileExists(atPath: directory.path) {
            guard let enumerator = fileManager.enumerator(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey]
            ) else {
                continue
            }
            for case let url as URL in enumerator where url.pathExtension == "png" {
                if snapshotFileName(for: url) == expectedName {
                    let modificationDate = (try? url.resourceValues(
                        forKeys: [.contentModificationDateKey]
                    ).contentModificationDate) ?? .distantPast
                    if newestMatch?.modificationDate ?? .distantPast < modificationDate {
                        newestMatch = (url, modificationDate)
                    }
                }
            }
        }
        return newestMatch?.url
    }

    var snapshotRecordDirectories: [URL] {
        [
            URL(fileURLWithPath: "/tmp/snapshot-records_64"),
            URL(fileURLWithPath: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD_DIR"] ?? "/tmp/snapshot-records"),
        ]
    }

    func snapshotFileName(identifier: String?) -> String {
        if let identifier, !identifier.isEmpty {
            return "\(snapshotTestMethodName)_\(identifier)"
        }
        return snapshotTestMethodName
    }

    func snapshotFileName(for url: URL) -> String {
        url.deletingPathExtension().lastPathComponent
            .replacingOccurrences(of: #"@\d+x$"#, with: "", options: .regularExpression)
    }

    var snapshotTestMethodName: String {
        let methodName: String
        if let lastDotIndex = name.lastIndex(of: ".") {
            methodName = String(name[name.index(after: lastDotIndex)...])
        } else if name.hasPrefix("-["),
                  let methodStartIndex = name.lastIndex(of: " "),
                  let methodEndIndex = name.lastIndex(of: "]") {
            methodName = String(name[name.index(after: methodStartIndex)..<methodEndIndex])
        } else {
            methodName = name
        }
        return methodName.replacingOccurrences(of: "()", with: "")
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
