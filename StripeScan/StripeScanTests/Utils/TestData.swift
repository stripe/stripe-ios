//
//  TestData.swift
//  CardVerifyTests
//
//  Created by Jaime Park on 9/22/21.
//

import Foundation

// note: This class is to find the test bundle
private class TestDataClass {}

enum TestData: String {
    case initializeClient = "InitializeClient"

    func getBundle() -> Bundle {
        return Bundle(for: TestDataClass.self)
    }

    private func dataFromJSONFile(_ name: String) throws -> Data {
        let bundle = self.getBundle()
        let filePath = bundle.path(forResource: name, ofType: "json")
        return try Data(contentsOf: URL(fileURLWithPath: filePath!)) 
    }

    func dataFromJSONFile() throws -> Data {
        return try dataFromJSONFile(self.rawValue)
    }
}
