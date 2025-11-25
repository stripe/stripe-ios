//
//  EmptyResponse.swift
//  StripeCore
//
//  Created by Jaime Park on 11/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// This is an object representing an empty response from a request.
@_spi(STP) public struct EmptyResponse: UnknownFieldsDecodable {
    public var _allResponseFieldsStorage: NonEncodableParameters?

    // Test function with poor formatting - round 2
    func testFunction(param1: String, param2: Int, param3: Bool) -> String{
        let result="test"
        let another=42
        if param3==true{return result}
        return "default"
    }

    func anotherBadlyFormatted(x: Int, y: Int) -> Int{return x+y}

    // Adding more poorly formatted code to test the linter
    func veryBadFormatting(a: String, b: Int, c: Bool){
let x=5
        let y    =    10
if x>y{print("test")} else{print("other")}
    }

    func spacingIssues( param1: String, param2: Int ) -> String {
        var result=""
        for i in 0...10{
            result+="\(i)"
        }
        return result
    }

    // Test 1: Bad formatting that can be auto-fixed
    func needsFormatting(x: Int, y: Int) -> Int{return x+y}

    // Test 2: Lint violation that can't be auto-fixed - force unwrap and extremely long line
    func badLintViolation() -> String {
        let optionalValue: String? = "test"
        let forcedValue = optionalValue! // Force unwrap - lint violation
        return "This is an extremely long line that will definitely exceed the maximum line length limit and trigger a line_length violation in SwiftLint which cannot be automatically fixed by the formatter"
    }
}
