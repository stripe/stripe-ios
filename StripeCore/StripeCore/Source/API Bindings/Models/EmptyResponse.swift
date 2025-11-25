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
    func testFunction(param1:String,param2:Int,param3:Bool)->String{
        let result="test"
        let another=42
        if param3==true{return result}
        return "default"
    }

    func anotherBadlyFormatted(x:Int,y:Int)->Int{return x+y}
}
