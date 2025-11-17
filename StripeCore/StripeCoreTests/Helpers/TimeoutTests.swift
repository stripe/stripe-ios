//
//  TimeoutTests.swift
//  StripeCore
//
//  Created by Joyce Qin on 10/28/25.
//

import Foundation

@_spi(STP) @testable import StripeCore
import XCTest

class TimeoutTests: XCTestCase {
    struct TestError: Error {}

    func testWithTimeout_allOperationsCompleteBeforeTimeout() async {
        let operation1 = {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            return "Result1"
        }

        let operation2 = {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            return 42
        }

        let operation3 = {
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            return true
        }

        let (result1, result2, result3) = await withTimeout(
            1.0,
            operation1, operation2, operation3
        )

        // Results should match operation positions, not completion order
        guard case .success(let value1) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value1, "Result1")

        guard case .success(let value2) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value2, 42)

        guard case .success(let value3) = result3 else {
            XCTFail("Operation 3 should succeed")
            return
        }
        XCTAssertEqual(value3, true)
    }

    func testWithTimeout_allOperationsTimeout() async {

        let operation1 = {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
            return "Should not complete"
        }

        let operation2 = {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
            return 999
        }

        let (result1, result2) = await withTimeout(
            0.1,
            operation1, operation2
        )

        guard case .failure(let error1) = result1 else {
            XCTFail("Operation 1 should not complete")
            return
        }
        XCTAssertTrue(error1 is TimeoutError)

        guard case .failure(let error2) = result2 else {
            XCTFail("Operation 2 should not complete")
            return
        }
        XCTAssertTrue(error2 is TimeoutError)
    }

    func testWithTimeout_someOperationsTimeout() async {
        let operation1 = {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s - completes
            return "Fast"
        }

        let operation2 = {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5s - times out
            return "Slow"
        }

        let (result1, result2) = await withTimeout(
            1,
            operation1, operation2
        )

        guard case .success(let value) = result1 else {
            XCTFail("Operation 1 should succeed")
            return
        }
        XCTAssertEqual(value, "Fast")

        guard case .failure(let error) = result2 else {
            XCTFail("Operation 2 should not complete")
            return
        }
        XCTAssertTrue(error is TimeoutError)
    }

    func testWithTimeout_singleOperation() async {
        let result = await withTimeout(1.0) {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            return "Single"
        }

        guard case .success(let value) = result else {
            XCTFail("Operation should succeed")
            return
        }
        XCTAssertEqual(value, "Single")
    }

    func testWithTimeout_singleOperationTimesOut() async {
        let result = await withTimeout(0.1) {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5s
            return "Should timeout"
        }

        guard case .failure(let error) = result else {
            XCTFail("Operation should not complete")
            return
        }
        XCTAssertTrue(error is TimeoutError)
    }

    func testWithTimeout_operationsThrowErrors() async {
        let operation1 = {
            throw TestError()
        }

        let operation2 = {
            return "Success"
        }

        let (result1, result2) = await withTimeout(
            1.0,
            operation1, operation2
        )

        guard case .failure(let error) = result1 else {
            XCTFail("Operation 1 should throw error")
            return
        }
        XCTAssertTrue(error is TestError)

        guard case .success(let value) = result2 else {
            XCTFail("Operation 2 should succeed")
            return
        }
        XCTAssertEqual(value, "Success")
    }

    func testWithTimeout_parallel() async {
        // All operations start at the same time, so total time should be ~0.5s
        let startTime = Date()

        let operation1 = {
            try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
            return 1
        }

        let operation2 = {
            try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
            return 2
        }

        let operation3 = {
            try await Task.sleep(nanoseconds: 400_000_000) // 0.4s
            return 3
        }

        let (result1, result2, result3) = await withTimeout(
            1.0,
            operation1, operation2, operation3
        )

        let elapsed = Date().timeIntervalSince(startTime)

        XCTAssertEqual(try result1.get(), 1)
        XCTAssertEqual(try result2.get(), 2)
        XCTAssertEqual(try result3.get(), 3)

        // Should complete in ~0.4s (parallel execution), not 1.2s (sequential)
        XCTAssertLessThan(elapsed, 0.8)
    }
}
