//
//  MockData.swift
//  StripeCoreTestUtils
//
//  Created by Mel Ludowise on 10/27/21.
//

import Foundation
@testable @_spi(STP) import StripeCore

/// Protocol for easily opening JSON mock files
public protocol MockData: RawRepresentable where RawValue == String {
    associatedtype ResponseType: StripeDecodable
    var bundle: Bundle { get }
}

public extension MockData {
    var url: URL {
        return bundle.url(forResource: rawValue, withExtension: "json")!
    }

    func data() throws -> Data {
        return try Data(contentsOf: url)
    }

    func make() throws -> ResponseType {
        let result: Result<ResponseType, Error> = STPAPIClient.decodeResponse(data: try data(), error: nil)
        switch result {
        case .success(let response):
            return response
        case .failure(let error):
            throw error
        }
    }
}
