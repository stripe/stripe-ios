//  Converted to Swift 5.8.1 by Swiftify v5.8.28463 - https://swiftify.com/
//
//  STPTestUtils.swift
//  Stripe
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import ObjectiveC

class STPTestUtils: NSObject {
    class func jsonNamed(_ name: String?) -> [AnyHashable : Any]? {
        let data = self.data(fromJSONFile: name)
        if let data {
            return try? JSONSerialization.jsonObject(with: data, options: 0 as? JSONSerialization.ReadingOptions) as? [AnyHashable : Any]
        }
        return nil
    }

    /// Using runtime inspection, what are all the property names for this object?
    /// - Parameter object: the object to introspect
    /// - Returns: list of property names, usable with `valueForKey:`
    class func propertyNamesOf(_ object: NSObject?) -> [String]? {
        var propertyCount: UInt
        let propertyList = class_copyPropertyList(type(of: object), UnsafeMutablePointer<UInt32>(mutating: &propertyCount)) as? objc_property_t
        var propertyNames = [AnyHashable](repeating: 0, count: Int(propertyCount))

        for i in 0..<Int(propertyCount) {
            let property = propertyList?[i] as? objc_property_t
            var propertyName: String?
            if let property {
                propertyName = String(utf8String: property_getName(property))
            }
            propertyNames.append(propertyName ?? "")
        }
        free(propertyList)
        return propertyNames as? [String]
    }

    // MARK: -

    class func testBundle() -> Bundle? {
        return Bundle(for: STPTestUtils.self)
    }

    class func data(fromJSONFile name: String?) -> Data? {
        let bundle = self.testBundle()
        let path = bundle?.path(forResource: name, ofType: "json")

        if path == nil {
            // Missing JSON file
            return nil
        }
        var jsonString: String?
        do {
            jsonString = try String(contentsOfFile: path ?? "", encoding: .utf8)
        } catch {
            // File read error
            return nil
        }

        // Strip all lines that begin with `//`
        var jsonLines: [AnyHashable] = []

        for line in jsonString?.components(separatedBy: "\n") ?? [] {
            if !line.hasPrefix("//") {
                jsonLines.append(line)
            }
        }

        return jsonLines.joined(separator: "\n").data(using: .utf8)
    }
}

/// Custom assertion function to compare to UIImage instances.
/// On iOS 9, `XCTAssertEqualObjects` incorrectly fails when provided with identical images.
/// This just calls `XCTAssertEqualObjects` with the `UIImagePNGRepresentation` of each
/// image. Can be removed when we drop support for iOS 9.
/// - Parameters:
///   - image1: First UIImage to compare
///   - image2: Second UIImage to compare
func STPAssertEqualImages(_ image1: UIImage?, _ image2: UIImage?) {
    XCTAssertEqual(image1?.pngData(), image2?.pngData())
}