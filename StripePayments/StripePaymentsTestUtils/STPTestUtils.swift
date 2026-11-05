//
//  STPTestUtils.swift
//  StripePaymentsTestUtils
//
//  Created by Ben Guo on 7/14/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
import XCTest

public class STPTestUtils: NSObject {
    /// Returns the contents of `Mock Files/<name>.json` as a dictionary, ignoring lines that begin with `//`.
    public class func jsonNamed(_ name: String) -> [AnyHashable: Any]! {
        guard let data = dataFromJSONFile(name) else {
            return nil
        }
        return (try? JSONSerialization.jsonObject(with: data)) as? [AnyHashable: Any]
    }

    /// The descriptions of the values of the stored properties of `object`, keyed by property name.
    public class func storedPropertyDescriptions(of object: Any) -> [String: String] {
        var descriptions: [String: String] = [:]
        var mirror: Mirror? = Mirror(reflecting: object)
        while let current = mirror {
            for child in current.children {
                if let label = child.label {
                    descriptions[label] = String(describing: child.value)
                }
            }
            mirror = current.superclassMirror
        }
        return descriptions
    }

    static var testBundle: Bundle {
        return Bundle(for: STPTestUtils.self)
    }

    static func dataFromJSONFile(_ name: String) -> Data? {
        let bundle = testBundle
        guard let path = bundle.path(forResource: name, ofType: "json", inDirectory: "Mock Files") else {
            print("Missing file: \(name) in bundle: \(bundle)")
            return nil
        }
        guard let jsonString = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        // Strip all lines that begin with `//`
        let jsonLines = jsonString.components(separatedBy: "\n").filter { !$0.hasPrefix("//") }
        return jsonLines.joined(separator: "\n").data(using: .utf8)
    }
}

/// Asserts that two images have the same PNG representation.
public func STPAssertEqualImages(
    _ image1: UIImage?,
    _ image2: UIImage?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(image1?.pngData(), image2?.pngData(), file: file, line: line)
}
